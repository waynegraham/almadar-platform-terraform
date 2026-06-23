FROM node:22-alpine AS deps

WORKDIR /opt/app

COPY package.json package-lock.json ./
RUN npm ci

FROM node:22-alpine AS build

WORKDIR /opt/app
ENV NEXT_TELEMETRY_DISABLED=1

COPY --from=deps /opt/app/node_modules ./node_modules
COPY . .
RUN npm run build
RUN npm prune --omit=dev

FROM node:22-alpine AS runtime

WORKDIR /opt/app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV FRONTEND_PORT=3000

COPY --from=build /opt/app ./

EXPOSE 3000

CMD ["npm", "run", "start", "--", "--hostname", "0.0.0.0", "--port", "3000"]
