FROM rust:1.93-alpine AS build
WORKDIR /app

RUN --mount=type=bind,source=src,target=src \
    --mount=type=bind,source=Cargo.toml,target=Cargo.toml \
    --mount=type=bind,source=Cargo.lock,target=Cargo.lock \
    --mount=type=cache,target=/app/target/ \
    --mount=type=cache,target=/usr/local/cargo/registry/ \
    cargo build --locked --profile docker-release && cp ./target/docker-release/hatefeed_daemon /bin/hatefeed

FROM scratch AS final
COPY --from=build ./bin/hatefeed hatefeed
CMD ["/hatefeed"]
