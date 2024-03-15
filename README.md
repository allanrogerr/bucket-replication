# Bucket chain replication
# Replicate objects between endpoints as part of a replication chain. Tag as replicated for post-processing.
```bash
docker build --tag replicate
```

# Run using a cron schedule
## Syntax
```bash
docker run --name replicate0 -d localhost:5000/replicate:latest /setup-cron.sh \
source-endpoint \
source-accesskey \
source-secretkey \
target-endpoint \
target-accesskey \
target-secretkey \
source-bucket \
source-prefix \
source-alias \
source-mc-binary \
retry \
cron-schedule
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
"" \
"acme-edge-0" \
"https://dl.minio.io/client/mc/release/linux-amd64/mc" \
"10" \
"* * * * *"
```

# Run as single job
## Syntax
```bash
docker run --name replicate0 -d localhost:5000/replicate:latest /tag.sh \
source-endpoint \
source-accesskey \
source-secretkey \
target-endpoint \
target-accesskey \
target-secretkey \
source-bucket \
source-prefix \
source-alias \
source-mc-binary \
retry
```

## Example
```bash
docker run --name replicate -d localhost:5000/replicate:latest /tag.sh \
"http://acme-edge-0.minio.training:10000" \
"minioadmin" \
"minioadmin" \
"http://acme-central-0.minio.training:10000" \
"minioadmin" \
"minioadmin" \
"edge-0" \
"" \
"acme-edge-0" \
"https://dl.minio.io/client/mc/release/linux-amd64/mc" \
"5"
```