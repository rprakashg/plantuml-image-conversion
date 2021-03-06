FROM golang:latest as builder

ENV GO111MODULE=on

WORKDIR /go/src/github.com/rprakashg/plantuml-image-converter

COPY . .

RUN go mod tidy

RUN test -z "$(gofmt -l $(find . -type f -name '*.go' -not -path "./vendor/*"))" || { echo "Run \"gofmt -s -w\" on your Golang code"; exit 1; }

RUN go test $(go list ./...) -cover \
    && CGO_ENABLED=0 GOOS=${OS} GOARCH=${ARCH} go build -a -installsuffix cgo -o plantuml-image-converter

FROM alpine:3.6

ARG PLANTUML_VERSION=1.2019.4
ENV LANG en_US.UTF-8

COPY entrypoint.sh /root/

RUN apk --no-cache add openjdk8 curl \
    && chmod +x /root/entrypoint.sh

#plantuml
RUN apk add --no-cache graphviz ttf-droid ttf-droid-nonlatin \
    && mkdir /app \
    && curl -L https://sourceforge.net/projects/plantuml/files/plantuml.${PLANTUML_VERSION}.jar/download -o /app/plantuml.jar \
    && apk del curl

COPY --from=builder /go/src/github.com/rprakashg/plantuml-image-converter/plantuml-image-converter /app/plantuml-image-converter

ENV PLANTUML_JAR /app/plantuml.jar

EXPOSE 8080

ENTRYPOINT [ "/root/entrypoint.sh" ]

CMD ["start"]

