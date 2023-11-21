FROM quay.io/projectquay/golang:1.20 as builder

WORKDIR /go/src/app
COPY . .
# RUN go get винесено в Makefile
RUN make build

FROM scratch
#FROM alpine:latest
WORKDIR /
COPY --from=builder /go/src/app/kbot .
COPY --from=alpine:latest /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
ENTRYPOINT ["./kbot"]
# CMD [ "go" ]
