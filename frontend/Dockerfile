# Stage 1: build the React app
FROM node:26-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
ARG GIT_SHA=local
ENV GITHUB_SHA=$GIT_SHA
RUN npm test && npm run build

# Stage 2: serve with Nginx and proxy API calls to the backend
FROM nginx:1.31-alpine
# Pull in Alpine security fixes published after the base image was built (keeps Trivy clean).
# hadolint ignore=DL3017
RUN apk upgrade --no-cache
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
HEALTHCHECK --interval=15s --timeout=3s --retries=5 \
  CMD wget -qO- http://127.0.0.1/healthz || exit 1
