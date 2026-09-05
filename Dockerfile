# ── Stage 1: Build Flutter Web ────────────────────────────────────────────────
FROM ubuntu:24.04 AS flutter-builder

ENV DEBIAN_FRONTEND=noninteractive

# Minimal deps for a web-only Flutter build (no Android/JDK/OpenGL needed)
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl git unzip xz-utils zip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clone latest stable Flutter SDK from GitHub
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${PATH}:${FLUTTER_HOME}/bin"
RUN git clone --depth 1 --branch stable \
      https://github.com/flutter/flutter.git ${FLUTTER_HOME}

# Opt out of analytics
RUN flutter config --no-analytics

# Render's Docker runs in a rootless user namespace — tar fails to change
# ownership for uids/gids that don't exist in the namespace.
# Wrap tar to always pass --no-same-owner to suppress the chown calls.
RUN printf '#!/bin/sh\nexec /usr/bin/tar --no-same-owner "$@"\n' \
      > /usr/local/bin/tar && chmod +x /usr/local/bin/tar

# Pre-fetch only the web engine artifacts (prevents Gradle/Android downloads)
RUN flutter precache --web --no-android --no-ios \
      --no-linux --no-macos --no-windows --no-fuchsia

WORKDIR /app/frontend
COPY frontend/pubspec.yaml frontend/pubspec.lock ./
RUN flutter pub get
COPY frontend/ .
RUN flutter build web --release

# ── Stage 2: Build Go binary ───────────────────────────────────────────────────
FROM golang:1.22-alpine AS go-builder
WORKDIR /app
COPY backend/go.mod backend/go.sum ./
RUN go mod download
COPY backend/ .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o server .

# ── Stage 3: Final runtime image ───────────────────────────────────────────────
FROM alpine:3.20
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /app

# Go binary
COPY --from=go-builder /app/server ./server

# Flutter web output
COPY --from=flutter-builder /app/frontend/build/web ./static

ENV RENDER=true
ENV STATIC_DIR=./static

EXPOSE 10000
CMD ["./server"]
