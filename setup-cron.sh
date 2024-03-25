#!/usr/bin/env bash

# Run replication tool
source_endpoint="${1}"
source_access_key="${2}"
source_secret_key="${3}"
target_endpoint="${4}"
target_access_key="${5}"
target_secret_key="${6}"
source_bucket="${7}"
source_bucket_purge="${8}"
source_prefix="${9}"
source_alias="${10}"
source_mc_binary="${11}"
retry="${12}"
cron_schedule="${13}"
webhook="${14}"
expiry="${15}"

echo Parameters:
echo Source Endpoint: "$source_endpoint"
echo Source Access Key: "$source_access_key"
echo Source Access Key: "$source_secret_key"
echo Target Endpoint: "$target_endpoint"
echo Target Access Key: "$target_access_key"
echo Target Secret Key: "$target_secret_key"
echo Source Bucket: "$source_bucket"
echo Source Bucket Purge: "$source_bucket_purge"
echo Source Prefix: "$source_prefix"
echo Source Alias: "$source_alias"
echo Source MC Binary: "$source_mc_binary"
echo Retry: "$retry"
echo CRON schedule: "$cron_schedule"
echo Webhook: "$webhook"
echo Expiry: "$expiry"

echo "${cron_schedule} (cd /; \
/tag.sh \"${source_endpoint}\" \"${source_access_key}\" \"${source_secret_key}\" \
\"${target_endpoint}\" \"${target_access_key}\" \"${target_secret_key}\" \
\"${source_bucket}\" \"${source_bucket_purge}\" \"${source_prefix}\" \
\"${source_alias}\" \"${source_mc_binary}\" \"${retry}\" \"${webhook}\" 2>&1; \
/purge.sh \"${source_endpoint}\" \"${source_access_key}\" \"${source_secret_key}\" \
\"${source_bucket_purge}\" \"${source_prefix}\" \
\"${source_alias}\" \"${source_mc_binary}\" \"${retry}\" \"${webhook}\" \"${expiry}\" 2>&1) > /proc/1/fd/1 2>&1" | crontab -

# Create a wait point for cron
service cron start
echo "cron schedule: ${cron_schedule}"
while true;
do
	sleep 1;
done