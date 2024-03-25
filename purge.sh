#!/bin/bash

# Improve readability
endpoint="${1}"
access_key="${2}"
secret_key="${3}"
bucket="${4}"
prefix="${5}"
alias="${6}"
mc_binary="${7}"
retry="${8}"
webhook="${9}"
expiry_condition="${10}"

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
# Find record keeping bucket
if ! ./mc ls "$alias"/"$bucket" >/dev/null;
then
	echo Bucket "$alias"/"$bucket" is missing. Exiting
fi

# Define default retry=3
if [[ -z $retry ]];
then
	retry=3
fi

# Define purge threshold
expiry_threshold=$(date -u -d "$expiry_condition" +"%F-%H")

# Review markers for purging
failed_prefix=0
failed_marker=0
purged_prefix=0
purged_marker=0
total=0
purge_identifiers=$(./mc ls "$alias"/"$bucket" --json | jq .key | tr -d '"')
if [ "$purge_identifiers" = "" ];
then
	echo "No identifiers to purge"
else
	for marker in $purge_identifiers;
	do
		# Get bucket and prefix to purge
		IFS="_" read -ra purge_identifier <<< "$marker"
		if [[ ${#purge_identifier[@]} -ne 2 ]];
		then
			echo Could not derive bucket and prefix to be purged from "$purge_identifier"
			continue
		fi
		purge_bucket=${purge_identifier[0]}
		purge_prefix=${purge_identifier[1]}
		# Define current record keeping prefix
		purge_prefix_tag="$(echo $purge_prefix | sed 's/\-/\//g')"

		# Test expiration
		purge_prefix_date_format=$(echo "$purge_prefix" | rev | sed "s/\-/ /" | rev)
		purge_prefix_date=$(date -u -d "$purge_prefix_date_format" '+%F-%H')

		# Not a candidate; skip
		if [ $(date -u -d "$purge_prefix_date_format" +%s) -ge $(date -u -d "$expiry_condition" +%s) ];
		then
			echo Prefix date "$purge_prefix_date"\($(date -u -d "$purge_prefix_date_format" +%s)\) is not older than expiry threshold "$(date -u -d "$expiry_condition" '+%F-%H')"\($(date -u -d "$expiry_condition" +%s)\) and so is not a candidate for purging
			continue
		fi

		echo Prefix date "$purge_prefix_date"\($(date -u -d "$purge_prefix_date_format" +%s)\) is older than expiry threshold "$(date -u -d "$expiry_condition" '+%F-%H')"\($(date -u -d "$expiry_condition" +%s)\) - attempting to purge
		for r in $(seq 1 $retry);
		do
			if [ "$r" == "$retry" ];
			then
				failed_prefix=$((failed_prefix+1))
			fi
			echo Purging prefix "$alias"/"$purge_bucket"/"$purge_prefix_tag"
			read -r purge_prefix_response < <(./mc rm "$alias"/"$purge_bucket"/"$purge_prefix_tag" 2>&1)
			if echo "$purge_prefix_response" | grep -q "Object does not exist";
			then
				echo Prefix "$alias"/"$purge_bucket"/"$purge_prefix_tag" was already purged
				purged_prefix=$((purged_prefix+1))
				break
			elif echo "$purge_prefix_response" | grep -q "Removed";
			then
				echo Purged prefix "$alias"/"$purge_bucket"/"$purge_prefix_tag"
				purged_prefix=$((purged_prefix+1))
				break
			else
				echo Could not purge prefix "$alias"/"$purge_bucket"/"$purge_prefix_tag" - "$purge_prefix_response" - retry $r
				sleep 1
				continue
			fi
		done
		for r in $(seq 1 $retry);
		do
			if [ "$r" == "$retry" ];
			then
				failed_marker=$((failed_marker+1))
			fi
			echo Purging marker "$alias"/"$bucket"/"$marker"
			read -r purge_marker_response < <(./mc rm "$alias"/"$bucket"/"$marker" 2>&1)
			if echo "$purge_marker_response" | grep -q "Object does not exist";
			then
				echo Marker "$alias"/"$bucket"/"$marker" was already purged
				purged_marker=$((purged_marker+1))
				break
			elif echo "$purge_marker_response" | grep -q "Removed";
			then
				echo Purged marker "$alias"/"$bucket"/"$marker"
				purged_marker=$((purged_marker+1))
				break
			else
				echo Could not purge marker "$alias"/"$bucket"/"$marker" - "$purge_marker_response" - retry $r
				sleep 1
				continue
			fi
		done
	done
fi

data="{\"failed_prefix\": ${failed_prefix}, \"failed_marker\": ${failed_marker}, \"purged_prefix\": ${purged_prefix}, \"purged_marker\": ${purged_marker}, \"total\": ${#purge_identifiers[@]}}"
echo "$data"
if [ -n "${webhook}" ];
then
	curl --silent --output /dev/null -X POST -H 'Content-Type: application/json' -d "$data" ${webhook}
fi

