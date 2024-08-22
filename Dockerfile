FROM nginx:stable-alpine

COPY build/web /usr/share/nginx/html
COPY custom/mime.types /etc/nginx/
