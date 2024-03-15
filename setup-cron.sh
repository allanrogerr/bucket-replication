#!/usr/bin/env bash

# Run replication tool
source_endpoint="${1}"
source_access_key="${2}"
source_secret_key="${3}"
target_endpoint="${4}"
target_access_key="${5}"
target_secret_key="${6}"
source_bucket="${7}"
source_prefix="${8}"
source_alias="${9}"
source_mc_binary="${10}"
retry="${11}"
cron_schedule="${12}"

echo "${cron_schedule} (cd /; /tag.sh \"${source_endpoint}\" \"${source_access_key}\" \"${source_secret_key}\" \
\"${target_endpoint}\" \"${target_access_key}\" \"${target_secret_key}\" \"${source_bucket}\" \"${source_prefix}\" \
\"${source_alias}\" \"${source_mc_binary}\" \"${retry}\") > /proc/1/fd/1 2>&1" | crontab -

# Create a wait point for cron
service cron start
echo "cron schedule: ${cron_schedule}"
while true;
do
	sleep 1;
done