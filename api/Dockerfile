FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN apk add --no-cache python3 build-base \
    && npm ci

FROM node:18-alpine

RUN apk add --no-cache python3 ffmpeg yt-dlp

WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY . .

EXPOSE 3000

CMD ["npm", "start"]