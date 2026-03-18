FROM debian:bookworm-slim AS build

ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    libglu1-mesa \
    unzip \
    xz-utils \
    zip \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/flutter/flutter.git --depth 1 --branch stable "${FLUTTER_HOME}"

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./

RUN flutter config --enable-web && flutter pub get

COPY . .

RUN flutter build web --release

FROM nginx:1.27-alpine

RUN apk add --no-cache gettext

COPY docker/entrypoint.sh /entrypoint.sh
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/build/web /usr/share/nginx/html

RUN chmod +x /entrypoint.sh

ENV PORT=10000

EXPOSE 10000

ENTRYPOINT ["/entrypoint.sh"]
