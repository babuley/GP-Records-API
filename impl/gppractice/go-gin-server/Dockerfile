FROM golang:1.13 AS build
WORKDIR /go/src
COPY go ./go
COPY go.mod .
COPY data ./data
COPY main.go .

ENV CGO_ENABLED=0

RUN addgroup --system projects && adduser --system projects --ingroup projects
RUN chown -R projects:projects /go/src

USER projects
RUN go get -d -v ./...

RUN go build -a -installsuffix cgo -o gprecords .
ENV GIN_MODE=release
EXPOSE 8080
CMD ["./gprecords"]

