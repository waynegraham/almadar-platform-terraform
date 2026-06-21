import type { Core } from '@strapi/strapi';

const config = ({ env }: Core.Config.Shared.ConfigParams): Core.Config.Plugin => ({
  upload: {
    config: {
      provider: 'aws-s3',
      providerOptions: {
        baseUrl: env('STRAPI_UPLOADS_BASE_URL'),
        rootPath: env('STRAPI_UPLOADS_ROOT_PATH', 'uploads'),
        s3Options: {
          credentials: {
            accessKeyId: env('AWS_ACCESS_KEY_ID'),
            secretAccessKey: env('AWS_SECRET_ACCESS_KEY'),
          },
          endpoint: env('AWS_ENDPOINT'),
          forcePathStyle: env.bool('AWS_S3_FORCE_PATH_STYLE', true),
          region: env('AWS_REGION', 'us-east-1'),
          params: {
            ACL: env('AWS_ACL', 'public-read'),
            Bucket: env('AWS_BUCKET', 'strapi-dev'),
            signedUrlExpires: env.int('AWS_SIGNED_URL_EXPIRES', 15 * 60),
          },
        },
      },
      actionOptions: {
        upload: {},
        uploadStream: {},
        delete: {},
      },
    },
  },
});

export default config;
