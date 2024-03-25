#!/usr/bin/env bash

# Improve readability
source_endpoint="${1}"
source_access_key="${2}"
source_secret_key="${3}"
target_endpoint="${4}"
target_access_key="${5}"
target_secret_key="${6}"
bucket="${7}"
bucket_purge="${8}"
prefix="${9}"
alias="${10}"
mc_binary="${11}"
retry="${12}"
webhook="${13}"

# date() { if type -t gdate &>/dev/null; then gdate "$@"; else date "$@"; fi }

# Setup:
# Acquire mc if not present
if ! which ./mc >/dev/null 2>&1;
then
	rm -rf ./mc
	wget -q "$mc_binary" -O mc
	chmod +x mc
	./mc alias set "$alias" "$source_endpoint" "$source_access_key" "$source_secret_key"
fi
# Create record keeping bucket
if ! ./mc ls "$alias"/"$bucket_purge" >/dev/null;
then
	./mc mb "$alias"/"$bucket_purge"
fi
# Map source prefix if not given
if [[ -z $prefix ]];
then
	echo No prefix given
	prefix=$(date -u +"%F-%H" | sed 's/\-/\//g')
fi

# Define current record keeping prefix
prefix_tag="$(echo $prefix | sed 's/\//\-/g')"

# Define default retry=3
if [[ -z $retry ]];
then
	retry=3
fi

# Run replication tool
marker_copied=false
for r in $(seq 1 $retry);
do
	repl_code=$(SRC_ENDPOINT="$source_endpoint" \
	SRC_ACCESS_KEY="$source_access_key" \
	SRC_SECRET_KEY="$source_secret_key" \
	TARGET_ENDPOINT="$target_endpoint" \
	TARGET_ACCESS_KEY="$target_access_key" \
	TARGET_SECRET_KEY="$target_secret_key" \
	./drrepl.sh "$bucket" "$prefix")

	# Test for success
	if [[ "$repl_code" = 0 ]];
	then
		break
	else
		echo $repl_code
	fi

	if [ "$r" == "$retry" ];
	then
		echo "could not run single bucket replication, exiting"
		break
	else
		# Compare latest source and target lists
		datafile=$(find *."$bucket"-"$prefix_tag".txt -type f -exec ls -t {} + | head -1)
		targetdatafile=$(find *."$bucket"-"$prefix_tag"-target.txt -type f -exec ls -t {} + | head -1)
		failed=$(diff -y --suppress-common-lines "${datafile}" "${targetdatafile}" | wc -l | tr -d ' ')
		total=$(cat "${datafile}" | wc -l | tr -d ' ')

		if [[ $failed -eq 0 ]];
		then
    	# No failures, note prefix as ready to purge
    	# Create dummy empty file marker
    	for retry_marker in $(seq 1 $retry);
      do
				cat /dev/null > /tmp/"$bucket"_"$prefix_tag"
				read -r copy_prefix_response < <(./mc cp /tmp/"$bucket"_"$prefix_tag" "$alias""/"$bucket_purge"" 2>&1)
				if echo "$copy_prefix_response" | grep -q "ERROR";
				then
					echo Could not copy marker - "$copy_prefix_response" - "$retry_marker"
					sleep 1
					continue
				else
					marker_copied=true
					echo Marker "$bucket"_"$prefix_tag" copied to "$alias""/"$bucket_purge""
					break
				fi
			done
		fi
	fi
	if [[ $marker_copied ]];
	then
		break
	fi
	sleep 1
done

data="{\"failed\": ${failed}, \"total\": ${total}, \"marker_copied\": $marker_copied, \"datafile\": \"${datafile}\", \"targetdatafile\": \"${targetdatafile}\" }"
echo "$data"
if [ -n "${webhook}" ];
then
	curl --silent --output /dev/null -X POST -H 'Content-Type: application/json' -d "$data" ${webhook}
fi