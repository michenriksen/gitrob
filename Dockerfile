FROM golang:alpine as build

RUN apk add --no-cache git perl-utils zip

WORKDIR /go/src/github.com/phantomSecrets

COPY go.mod go.sum ./
RUN gi get -u

COPY . .
RUN go build

FROM golang:alpine as deploy

COPY --from=build /go/src/phantomSecrets \
     /go/src/phantomSecrets/filesignatures.json \
     /go/src/phantomSecrets/contentsignatures.json \
    ./
ENTRYPOINT ["./phantomSecrets"]
