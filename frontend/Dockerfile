# ── Simple single-stage: Nginx serves static files ──────────────────────────
# We use the official nginx alpine image which is tiny (~23 MB)
FROM nginx:alpine

RUN apk update && apk upgrade --no-cache

# Remove the default nginx configuration
RUN rm /etc/nginx/conf.d/default.conf

# Copy our custom Nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the static HTML/CSS/JS files into the nginx web root
COPY index.html /usr/share/nginx/html/

# Expose HTTP port
EXPOSE 80

# Nginx starts automatically — CMD is inherited from base image
