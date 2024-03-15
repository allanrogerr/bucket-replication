#!/usr/bin/env bash

# Improve readability
src_bucket="$7"
src_prefix="$8"
src_alias="$9"
src_mc_binary="${10}"
retry="${11}"

# Default retry=3
if [[ -z $retry ]];
then
	retry=3
fi

# Run replication tool
for r in $(seq 1 $retry);
do
	repl_code=$(SRC_ENDPOINT="$1" \
	SRC_ACCESS_KEY="$2" \
	SRC_SECRET_KEY="$3" \
	TARGET_ENDPOINT="$4" \
	TARGET_ACCESS_KEY="$5" \
	TARGET_SECRET_KEY="$6" \
	./drrepl.sh "$src_bucket" "$src_prefix")

	# Test for success
	if [ "$repl_code" == 0 ];
	then
		break
	fi
	echo "retry $r"

	if [ "$r" == "$retry" ];
	then
		echo "could not run single bucket replication, exiting"
		exit 255
	fi
	sleep 1
done

# Acquire mc if not present
if ! which ./mc >/dev/null 2>&1; then
		wget -q "$src_mc_binary" -O mc
		chmod +x mc
		./mc alias set "$src_alias" "$1" "$2" "$3"
fi

# Acquire latest successful replication data
success=$(find copy_success.txt.* -type f -exec ls -t {} + | head -1)
while read -r line || [[ -n $line ]];
do
	tokens=$(echo "$line" | tr "," " ")
	if [[ ${#tokens} -ge 2 ]]; then
		# Tag objects as 'status=replicated', for subsequent ILM expiry
		./mc tag set "$src_alias"/"${tokens[0]}"/"${tokens[1]}" "status=replicated"
	fi
done < "$success"