FROM ubuntu:latest AS builder

RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa

RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"
RUN flutter doctor

WORKDIR /app

COPY pubspec.* ./
RUN flutter pub get

COPY . .

RUN flutter build web --release --no-wasm-dry-run

FROM nginx:alpine

COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]