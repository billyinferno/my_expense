FROM nginx:stable-alpine

COPY build/web /usr/share/nginx/html
