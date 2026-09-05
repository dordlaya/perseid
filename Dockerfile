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

# Opt out of analytics, then let flutter build web fetch only what it needs
RUN flutter config --no-analytics

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
