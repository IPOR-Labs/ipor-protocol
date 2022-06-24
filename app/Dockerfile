# FROM TAG: 16.14.2-alpine3.15
FROM node@sha256:38bc06c682ae1f89f4c06a5f40f7a07ae438ca437a2a04cf773e66960b2d75bc

WORKDIR /usr/src/app
COPY package*.json ./

RUN npm install
COPY . .

EXPOSE 3000
CMD npm run start

COPY .env /usr/src/.env
