FROM --platform=$BUILDPLATFORM alpine:3.21.3 AS certs
RUN apk add ca-certificates

FROM scratch AS kubeconform
LABEL org.opencontainers.image.authors="Redacid <sr@ios.in.ua>" \
      org.opencontainers.image.source="https://github.com/redacid/kubeconform/" \
      org.opencontainers.image.description="A Kubernetes manifests validation tool" \
      org.opencontainers.image.documentation="https://github.com/redacid/kubeconform/" \
      org.opencontainers.image.licenses="Apache License 2.0" \
      org.opencontainers.image.title="kubeconform" \
      org.opencontainers.image.url="https://github.com/redacid/kubeconform/"
COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY kubeconform /
ENTRYPOINT ["/kubeconform"]
