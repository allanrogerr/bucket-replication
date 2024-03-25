# Bucket chain replication
# Replicate objects between endpoints as part of a replication chain. Tag as replicated for post-processing.

# Notes
Code is broken up into two modules. As a cronjob, it can be run on a specific source bucket/target combination.
The condition for expiry e.g. (-7 days), retries and a reporting webhook can also be specified.
It runs on linux, restricted by the gnu date function.
```bash
tag
considers the current prefix based on the current utc time
runs custom replication tool for a given bucket and previously calculated prefix
if there is no difference between source and target sites wrt the bucket and prefix then
  create and copy a representation only (marker) of the prefix to a purge bucket on the source
report
```
```bash
purge
review if there are any markers in the purge bucket
for each of the markers
  derive the bucket and prefix to be purged
  compare the prefix format to the current date and the expiry condition
  e.g. prefix (2024/02/16/23) and expiry threshold (2024/03/24/23 - 7 days)
  if the prefix as a date is older than the expiry threshold then
    purge the prefix
  if the prefix is purged then
    purge the marker
report
```

# If necessary, build and push to a registry e.g. localhost:5000
```bash
docker run -d -p 5000:5000 --restart always --name registry registry:2
docker build --tag replicate:dev .
docker tag replicate:dev localhost:5000/replicate:latest
docker push localhost:5000/replicate:latest
```

# Run using a cron schedule
## Syntax
```bash
docker run --name replicate0 -d localhost:5000/replicate:latest /setup-cron.sh \
source_endpoint \
source_accesskey \
source_secretkey \
target_endpoint \
target_accesskey \
target_secretkey \
source_bucket \
source_bucket_purge \
source_prefix \
source_alias \
source_mc_binary \
retry \
cron_schedule \
webhook \
expiry 
```

## Example
```bash
docker run --name replicate0 -d localhost:5000/replicate:latest /setup-cron.sh \
"http://acme-edge-0.minio.training:10000" \
"minioadmin" \
"minioadmin" \
"http://acme-central-0.minio.training:10000" \
"minioadmin" \
"minioadmin" \
"edge-0" \
"ready-to-delete" \
"" \
"acme-edge-0" \
"https://dl.minio.io/client/mc/release/linux-amd64/mc" \
"10" \
"0 * * * *" \
"" \
"-7 days"
```

# Run single jobs
## Syntax
```bash
docker run --name replicate -d localhost:5000/replicate:latest /tag.sh \
source_endpoint \
source_accesskey \
source_secretkey \
target_endpoint \
target_accesskey \
target_secretkey \
bucket \
bucket_purge \
prefix \
alias \
mc_binary \
retry \
webhook
```
```bash
docker run --name replicate -d localhost:5000/replicate:latest /purge.sh \
endpoint \
access_key \
secret_key \
bucket \
bucket_purge \
prefix \
alias \
mc_binary \
retry \
webhook \
expiry_condition
```

## Examples
```bash
docker run --name replicate -d localhost:5000/replicate:latest /tag.sh \
"http://acme-edge-0.minio.training:10000" \
"minioadmin" \
"minioadmin" \
"http://acme-edge-0.minio.training:10000" \
"minioadmin" \
"minioadmin" \
"edge-0" \
"ready-to-delete" \
"" \
"acme-edge-0" \
"https://dl.minio.io/client/mc/release/linux-amd64/mc" \
"5" \
""
```
```bash
docker run --name replicate -d localhost:5000/replicate:latest /purge.sh \
"http://acme-edge-0.minio.training:10000" \
"minioadmin" \
"minioadmin" \
"edge-0" \
"ready-to-delete" \
"" \
"acme-edge-0" \
"https://dl.minio.io/client/mc/release/linux-amd64/mc" \
"5" \
"" \
"- 7 days"
```