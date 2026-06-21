import type { Core } from '@strapi/strapi';

const config = ({ env }: Core.Config.Shared.ConfigParams): Core.Config.Plugin => {
  const bucket = env('S3_BUCKET', env('AWS_BUCKET', 'strapi-dev'));

  return {
    upload: {
      config: {
        provider: 'aws-s3',
        providerOptions: {
          baseUrl: env('S3_PUBLIC_BASE_URL', env('STRAPI_UPLOADS_BASE_URL')),
          rootPath: env('S3_ROOT_PATH', env('STRAPI_UPLOADS_ROOT_PATH', 'uploads')),
          s3Options: {
            credentials: {
              accessKeyId: env('S3_ACCESS_KEY_ID', env('AWS_ACCESS_KEY_ID')),
              secretAccessKey: env('S3_SECRET_ACCESS_KEY', env('AWS_SECRET_ACCESS_KEY')),
            },
            endpoint: env('S3_ENDPOINT', env('AWS_ENDPOINT')),
            forcePathStyle: env.bool('S3_FORCE_PATH_STYLE', env.bool('AWS_S3_FORCE_PATH_STYLE', true)),
            region: env('S3_REGION', env('AWS_REGION', 'us-east-1')),
            params: {
              ACL: env('S3_ACL', env('AWS_ACL', 'public-read')),
              Bucket: bucket,
              signedUrlExpires: env.int(
                'S3_SIGNED_URL_EXPIRES',
                env.int('AWS_SIGNED_URL_EXPIRES', 15 * 60)
              ),
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
  };
};

export default config;
