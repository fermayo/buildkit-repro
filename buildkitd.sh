#!/bin/sh
set -ex

TAG=$(date +%s)

containerd &
CONTAINERD_PID=$!
sleep 1
buildkitd --debug --oci-worker=false --containerd-worker=true &
BUILDKIT_PID=$!

sleep 1
runc --version
ctr --version
buildctl --version

echo "===== Run with EXPORT"
go run examples/buildkit3/buildkit.go -buildkit=local | buildctl build --local buildkit-src=. --export-cache docker.io/buildkitdemo/cache:$TAG

echo "===== Cleaning up"
kill $BUILDKIT_PID
kill $CONTAINERD_PID
rm -fr /var/lib/buildkit
rm -fr /var/lib/containerd

containerd &
CONTAINERD_PID=$!
sleep 1
buildkitd --debug --oci-worker=false --containerd-worker=true &
BUILDKIT_PID=$!
sleep 1

echo "===== Run with IMPORT"
go run examples/buildkit3/buildkit.go -buildkit=local | buildctl build --local buildkit-src=. --import-cache docker.io/buildkitdemo/cache:$TAG
