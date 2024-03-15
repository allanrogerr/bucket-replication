FROM golang:1.21

ARG TAG

LABEL name="MinIO" \
      vendor="MinIO Inc <dev@min.io>" \
      maintainer="MinIO Inc <dev@min.io>" \
      version="${TAG}" \
      release="${TAG}" \
      summary="MinIO Operator brings native support for MinIO, Console, and Encryption to Kubernetes." \
      description="MinIO object storage is fundamentally different. Designed for performance and the S3 API, it is 100% open-source. MinIO is ideal for large, private cloud environments with stringent security requirements and delivers mission-critical availability across a diverse range of workloads."

COPY LICENSE /licenses/LICENSE

# Application
RUN mkdir -p /opt/replicate
WORKDIR /opt/replicate
COPY . /opt/replicate
COPY drrepl.sh /drrepl.sh
COPY setup-cron.sh /setup-cron.sh
COPY tag.sh /tag.sh

RUN chmod +x /drrepl.sh
RUN chmod +x /setup-cron.sh
RUN chmod +x /tag.sh

RUN go build -v -o replicate .
RUN mv /opt/replicate/replicate /drrepltool
RUN chmod +x /drrepltool

# Schedule
RUN apt-get update && apt-get install cron -y

WORKDIR /
