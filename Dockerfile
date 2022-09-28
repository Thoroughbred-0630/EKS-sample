FROM node:14.2.0 as builder

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY ["package.json", "./"]
RUN npm install
COPY [".", "./"]
# RUN npm run build

FROM nginx:alpine
WORKDIR /usr/share/nginx/html
# COPY --from=builder ["/usr/src/app/build", "./"]
COPY ["nginx/default.conf", "/etc/nginx/conf.d"]
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]