FROM rust:slim AS builder

WORKDIR /usr/src/cpu

COPY src/cpu/Cargo.toml ./Cargo.toml
COPY src/cpu/Cargo.lock ./Cargo.lock
COPY src/cpu/src ./src

RUN cargo build --release

FROM alpine:3.20 AS runtime

WORKDIR /work

# ./src/cpu/target/release/chesseng
RUN mkdir -p ./src/cpu/target/release
COPY --from=builder /usr/src/cpu/target/release/chesseng ./src/cpu/target/release/chesseng

COPY src/cpu/test.sh ./src/cpu/test.sh
COPY src/cpu/search.sh ./src/cpu/search.sh

RUN chmod +x ./src/cpu/test.sh ./src/cpu/search.sh ./src/cpu/target/release/chesseng

ENV RUNTIME=docker

ENTRYPOINT ["sh", "-lc", "./src/cpu/test.sh"]