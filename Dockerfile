# Flutter web is built locally (`flutter build web --release`)
# and the output is committed to backend/static/.
# Render's build network blocks storage.googleapis.com so Flutter
# cannot be built inside Docker on Render.

# ── Stage 1: Build Go binary ───────────────────────────────────────────────────
FROM golang:1.22-alpine AS go-builder
WORKDIR /app
COPY backend/go.mod backend/go.sum ./
RUN go mod download
COPY backend/ .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o server .

# ── Stage 2: Final runtime image ───────────────────────────────────────────────
FROM alpine:3.20
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /app

# Go binary
COPY --from=go-builder /app/server ./server

# Pre-built Flutter web (committed to repo under backend/static/)
COPY backend/static ./static

ENV RENDER=true
ENV STATIC_DIR=./static

EXPOSE 10000
CMD ["./server"]
