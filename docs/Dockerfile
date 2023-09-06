FROM node:18-alpine AS installer
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

COPY . .

RUN pnpm install

# Build the project
RUN pnpm run build

# production stage
FROM nginx:stable-alpine as production-stage
# mkdir called docs in /usr/share/nginx/html
RUN mkdir /usr/share/nginx/html/docs
COPY --from=installer /app/build /usr/share/nginx/html/docs
COPY --from=installer /app/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

