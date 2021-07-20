FROM golang:alpine as build

RUN apk add --no-cache git perl-utils zip

WORKDIR /go/src/github.com/gitrob

COPY . .
RUN go build

FROM golang:alpine as deploy

COPY --from=build /go/src/github.com/gitrob \
     /go/src/github.com/gitrob/filesignatures.json \
     /go/src/github.com/gitrob/contentsignatures.json \
    ./
ENTRYPOINT ["./gitrob"]
