FROM golang:alpine as build

RUN apk add --no-cache git perl-utils zip
RUN go get github.com/golang/dep/cmd/dep

WORKDIR /go/src/github.com/phantomSecrets
COPY Gopkg.lock Gopkg.toml ./
RUN dep ensure -vendor-only

COPY . .
RUN go build

FROM golang:alpine as deploy
COPY --from=build /go/src/github.com/phantomSecrets \
     /go/src/github.com/phantomSecrets/filesignatures.json \
     /go/src/github.com/phantomSecrets/contentsignatures.json \
    ./
ENTRYPOINT ["./phantomSecrets"]
