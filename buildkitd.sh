#!/bin/sh
set -ex

containerd &
buildkitd --debug --oci-worker=false --containerd-worker=true &

sleep 2
runc --version
ctr --version
buildctl --version

echo "===== Run with EXPORT"
go run examples/buildkit3/buildkit.go -buildkit=local | buildctl build --local buildkit-src=. --export-cache docker.io/buildkitdemo/cache:v1

echo "===== Run with IMPORT"
go run examples/buildkit3/buildkit.go -buildkit=local | buildctl build --local buildkit-src=. --import-cache docker.io/buildkitdemo/cache:v1
