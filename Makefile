SHELL := /bin/sh

.PHONY: bootstrap local-up local-down test lint

bootstrap:
	@if [ -f apps/frontend/package.json ]; then cd apps/frontend && npm install; fi
	@if [ -f apps/strapi/package.json ]; then cd apps/strapi && npm install; fi

local-up:
	docker compose up -d

local-down:
	docker compose down

test:
	@if [ -f apps/frontend/package.json ]; then cd apps/frontend && npm test; fi
	@if [ -f apps/strapi/package.json ] && npm --prefix apps/strapi run | grep -q " test"; then cd apps/strapi && npm test; else echo "No Strapi test script defined"; fi

lint:
	@if [ -f apps/frontend/package.json ]; then cd apps/frontend && npm run lint; fi
	@if [ -f apps/strapi/package.json ] && npm --prefix apps/strapi run | grep -q " lint"; then cd apps/strapi && npm run lint; else echo "No Strapi lint script defined"; fi

