import type { Core } from '@strapi/strapi';

const parseList = (value?: string) =>
  value
    ?.split(',')
    .map((item) => item.trim())
    .filter(Boolean) ?? [];

const config = ({ env }: Core.Config.Shared.ConfigParams): Core.Config.Middlewares => {
  const uploadSources = parseList(env('STRAPI_UPLOADS_CSP_SRC', 'http://localhost:9000'));

  return [
    'strapi::logger',
    'strapi::errors',
    {
      name: 'strapi::security',
      config: {
        contentSecurityPolicy: {
          useDefaults: true,
          directives: {
            'connect-src': ["'self'", 'https:', 'http:'],
            'img-src': ["'self'", 'data:', 'blob:', 'market-assets.strapi.io', ...uploadSources],
            'media-src': ["'self'", 'data:', 'blob:', 'market-assets.strapi.io', ...uploadSources],
            upgradeInsecureRequests: null,
          },
        },
      },
    },
    'strapi::cors',
    'strapi::poweredBy',
    'strapi::query',
    'strapi::body',
    'strapi::session',
    'strapi::favicon',
    'strapi::public',
  ];
};

export default config;
