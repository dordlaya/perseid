# ── Stage 1: Build Flutter Web ────────────────────────────────────────────────
FROM debian:bookworm-slim AS flutter-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
      curl git unzip xz-utils ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
ENV FLUTTER_VERSION=3.24.5
RUN curl -fsSL "https://storage.googleapis.com/flutter/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
      -o /tmp/flutter.tar.xz \
    && tar -xf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz
ENV PATH="/opt/flutter/bin:${PATH}"

# Disable analytics & telemetry
RUN flutter config --no-analytics && dart --disable-analytics

WORKDIR /app/frontend
COPY frontend/pubspec.yaml frontend/pubspec.lock ./
RUN flutter pub get
COPY frontend/ .
RUN flutter build web --release

# ── Stage 2: Build Go binary ───────────────────────────────────────────────────
FROM golang:1.22-alpine AS go-builder
WORKDIR /app/backend
# Download deps first (cached layer)
COPY backend/go.mod backend/go.sum ./
RUN go mod download
# Then copy source and build
COPY backend/ .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o server .

# ── Stage 3: Final runtime image ───────────────────────────────────────────────
FROM alpine:3.20
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /app

# Copy Go binary
COPY --from=go-builder /app/backend/server ./server

# Copy Flutter web output → served as static files
COPY --from=flutter-builder /app/frontend/build/web ./static

ENV RENDER=true
ENV STATIC_DIR=./static

EXPOSE 10000

CMD ["./server"]
