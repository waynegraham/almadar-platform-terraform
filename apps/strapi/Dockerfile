FROM node:22-alpine AS deps

WORKDIR /opt/app

COPY package.json package-lock.json ./
RUN npm ci

FROM node:22-alpine AS build

WORKDIR /opt/app
ENV NODE_ENV=production

COPY --from=deps /opt/app/node_modules ./node_modules
COPY . .
RUN npm run build
RUN npm prune --omit=dev

FROM node:22-alpine AS runtime

WORKDIR /opt/app
ENV NODE_ENV=production

COPY --from=build /opt/app ./

EXPOSE 1337

CMD ["npm", "run", "start"]
