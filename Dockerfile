FROM rust:1.68.2

WORKDIR /app
RUN apt update && apt install lld clang -y
COPY . .
ENV SQLX_OFFLINE true
RUN cargo build --release
ENTRYPOINT ["./target/release/zero2prod"]

# TODO: Zero 2 Rust 5.3.4 Running an Image.