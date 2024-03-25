#!/usr/bin/env bash

set -e -C -o pipefail

function init() {
    if ! which ./drrepltool >/dev/null 2>&1; then
        echo "drrepltool not found; please copy the tool to pwd"
        exit 255
    fi
    bucket="$1"
    prefix="$2"
    ts="$(date +%s)"
    datafile="$ts.$bucket-$(echo $prefix | sed 's/\//\-/g').txt"
    targetdatafile="$ts.$bucket-$(echo $prefix | sed 's/\//\-/g')-target.txt"
}

function main() {
    if ! ./drrepltool list --endpoint "${SRC_ENDPOINT}" --ak "${SRC_ACCESS_KEY}" --sk "${SRC_SECRET_KEY}" --bucket "${bucket}" --prefix "${prefix}" --data-file "${datafile}"; then
        echo "unable to list the entries from the source"
        exit 255
    fi

    if ! ./drrepltool copy --endpoint "${TARGET_ENDPOINT}" --ak "${TARGET_ACCESS_KEY}" --sk "${TARGET_SECRET_KEY}" --src-endpoint "${SRC_ENDPOINT}" --src-access-key "${SRC_ACCESS_KEY}" --src-secret-key "${SRC_SECRET_KEY}" --data-file "${datafile}" --bucket "${bucket}" --src-bucket "${bucket}"; then
        echo "unable to copy the entries to the target"
        exit 255
    fi

    if ! ./drrepltool list --endpoint "${TARGET_ENDPOINT}" --ak "${TARGET_ACCESS_KEY}" --sk "${TARGET_SECRET_KEY}" --bucket "${bucket}" --prefix "${prefix}" --data-file "${targetdatafile}"; then
        echo "unable to list the entries from the target"
        exit 255
    fi

    if ! cmp -s "${datafile}" "${targetdatafile}"; then
        echo "the list is different; please retry"
        exit 255
    fi
}

init "$@"
main "$@"
