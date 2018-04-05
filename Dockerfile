FROM golang:1.10-alpine3.7 AS build-buildkit
RUN apk --no-cache add curl build-base
ENV BUILDKIT_SHA=2aa3554778f6ffd455d058dcaf799525390e70a3
RUN mkdir -p /go/src/github.com/moby/buildkit && curl -sSL https://github.com/moby/buildkit/archive/${BUILDKIT_SHA}.tar.gz | tar --strip-components=1 -zxvC /go/src/github.com/moby/buildkit
WORKDIR /go/src/github.com/moby/buildkit
RUN go install -v ./cmd/buildctl
RUN go install -v ./cmd/buildkitd

FROM golang:1.10-alpine3.7 AS build-containerd
RUN apk --no-cache add git curl build-base btrfs-progs-dev linux-headers
ENV CONTAINERD_VERSION=1.0.3
RUN go get -d -v github.com/containerd/containerd
WORKDIR /go/src/github.com/containerd/containerd
RUN git checkout v${CONTAINERD_VERSION} && make

FROM golang:1.10-alpine3.7 AS build-runc
RUN apk --no-cache add bash git curl build-base libseccomp-dev
ENV RUNC_VERSION=1.0.0-rc5
RUN go get -d -v github.com/opencontainers/runc
WORKDIR /go/src/github.com/opencontainers/runc
RUN git checkout v${RUNC_VERSION}
RUN make runc

FROM golang:1.10-alpine3.7
RUN apk --no-cache add git xfsprogs e2fsprogs btrfs-progs libseccomp jq
ENV AWS_REGION=us-east-1
WORKDIR /go/src/github.com/moby/buildkit
ENTRYPOINT ["buildkitd.sh"]
VOLUME /var/lib
COPY --from=build-buildkit /go/bin/* /usr/local/bin/
COPY --from=build-containerd /go/src/github.com/containerd/containerd/bin/* /usr/local/bin/
COPY --from=build-runc /go/src/github.com/opencontainers/runc/runc /usr/local/bin/runc
RUN git clone https://github.com/moby/buildkit.git /go/src/github.com/moby/buildkit
COPY buildkitd.sh /usr/local/bin/buildkitd.sh
COPY config.json /root/.docker/config.json
