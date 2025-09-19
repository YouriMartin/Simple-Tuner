# Multi-stage Dockerfile to build and serve the Flutter Web app
# Build stage: use a pinned Flutter image for reproducibility
FROM ghcr.io/cirruslabs/flutter:3.24.4 AS build
WORKDIR /app

# Enable web just in case (no-op if already enabled)
RUN flutter config --enable-web

# Cache dependencies first
COPY pubspec.yaml pubspec.yaml
RUN flutter pub get

# Copy the rest of the project
COPY . .

# Build the web release bundle
RUN flutter build web --release --no-tree-shake-icons

# Runtime stage: Nginx to serve the static Flutter Web assets
FROM nginx:1.27-alpine AS runtime

# Copy custom nginx config with SPA fallback
COPY deployment/nginx.conf /etc/nginx/conf.d/default.conf

# Copy the built web files
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

# Simple healthcheck to ensure Nginx is serving
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD wget -qO- http://127.0.0.1/ >/dev/null 2>&1 || exit 1

# Default command
CMD ["nginx", "-g", "daemon off;"]
