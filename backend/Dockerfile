
# ---- Build Stages ----
FROM golang:1.25-alpine AS builder
WORKDIR /app

# Install git for go mod download if needed
RUN apk add --no-cache git

# Copy go mod and sum files
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source code
COPY . .

# Build the Go app (adjust output name as needed)
RUN CGO_ENABLED=0 GOOS=linux go build -o server ./cmd/server

# ---- Run Stage ----
FROM alpine:latest
WORKDIR /app

# Copy the built binary from builder
COPY --from=builder /app/server ./server

# Expose port (adjust as needed, e.g., 8080)
EXPOSE 8080

# Run the binary
ENTRYPOINT ["./server"]
