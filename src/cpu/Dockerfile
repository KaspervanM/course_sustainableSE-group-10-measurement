FROM rust:slim

ENV DEBIAN_FRONTEND=noninteractive
ENV RUNTIME=docker

WORKDIR /usr/src/cpu

RUN apt-get update && \
    apt-get install -y --no-install-recommends bash ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY src/cpu/Cargo.toml ./Cargo.toml
COPY src/cpu/Cargo.lock ./Cargo.lock

COPY src/cpu/src ./src

RUN cargo build --release --locked

COPY src/cpu/test.sh /usr/src/cpu/test.sh
COPY src/cpu/search.sh /usr/src/cpu/search.sh

RUN chmod +x /usr/src/cpu/test.sh /usr/src/cpu/search.sh /usr/src/cpu/target/release/chesseng
