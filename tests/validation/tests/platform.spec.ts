import { expect, request, test } from '@playwright/test';
import { S3Client, PutObjectCommand, HeadObjectCommand } from '@aws-sdk/client-s3';
import pg from 'pg';

const { Client } = pg;

type Env = {
  frontendUrl: string;
  strapiUrl: string;
  cantaloupeUrl: string;
  postgresHost: string;
  postgresPort: number;
  postgresDatabase: string;
  postgresUser: string;
  postgresPassword: string;
  s3Endpoint: string;
  s3Region: string;
  s3AccessKeyId: string;
  s3SecretAccessKey: string;
  s3ForcePathStyle: boolean;
  iiifBucket: string;
  strapiUploadToken: string;
};

const png1x1 = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
  'base64',
);

function required(name: string): string {
  const value = process.env[name];

  if (!value) {
    throw new Error(`${name} is required for platform validation tests`);
  }

  return value;
}

function optionalUrl(name: string, fallback: string): string {
  return process.env[name] ?? fallback;
}

function env(): Env {
  return {
    frontendUrl: optionalUrl('FRONTEND_URL', 'http://localhost:3000'),
    strapiUrl: optionalUrl('STRAPI_URL', 'http://localhost:1337'),
    cantaloupeUrl: optionalUrl('CANTALOUPE_URL', 'http://localhost:8182'),
    postgresHost: process.env.POSTGRES_HOST ?? 'localhost',
    postgresPort: Number(process.env.POSTGRES_PORT ?? '5432'),
    postgresDatabase: process.env.POSTGRES_DB ?? 'almadar',
    postgresUser: process.env.POSTGRES_USER ?? 'almadar',
    postgresPassword: process.env.POSTGRES_PASSWORD ?? 'change-me-postgres-password',
    s3Endpoint: process.env.S3_ENDPOINT ?? 'http://localhost:9000',
    s3Region: process.env.S3_REGION ?? 'us-east-1',
    s3AccessKeyId: process.env.S3_ACCESS_KEY_ID ?? 'almadar',
    s3SecretAccessKey: process.env.S3_SECRET_ACCESS_KEY ?? 'change-me-minio-password',
    s3ForcePathStyle: (process.env.S3_FORCE_PATH_STYLE ?? 'true') === 'true',
    iiifBucket: process.env.IIIF_BUCKET ?? 'iiif-dev',
    strapiUploadToken: required('STRAPI_UPLOAD_TOKEN'),
  };
}

function joinUrl(baseUrl: string, path: string): string {
  return `${baseUrl.replace(/\/$/, '')}${path}`;
}

function encodedIiifIdentifier(objectKey: string): string {
  return objectKey.split('/').map(encodeURIComponent).join('%2F');
}

test.describe.configure({ mode: 'serial' });

test.describe('platform validation', () => {
  const config = env();
  const runId = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
  const iiifObjectKey = `validation/${runId}.png`;

  test('Strapi health responds', async () => {
    const api = await request.newContext({ baseURL: config.strapiUrl });
    const response = await api.get('/');

    expect(response.status(), await response.text()).toBeLessThan(500);
    await api.dispose();
  });

  test('PostgreSQL accepts a query', async () => {
    const client = new Client({
      host: config.postgresHost,
      port: config.postgresPort,
      database: config.postgresDatabase,
      user: config.postgresUser,
      password: config.postgresPassword,
      ssl: (process.env.POSTGRES_SSL ?? 'false') === 'true' ? { rejectUnauthorized: false } : false,
    });

    await client.connect();
    const result = await client.query('select 1 as ok');
    await client.end();

    expect(result.rows).toEqual([{ ok: 1 }]);
  });

  test('Object storage accepts an IIIF object write', async () => {
    const s3 = new S3Client({
      endpoint: config.s3Endpoint,
      region: config.s3Region,
      forcePathStyle: config.s3ForcePathStyle,
      credentials: {
        accessKeyId: config.s3AccessKeyId,
        secretAccessKey: config.s3SecretAccessKey,
      },
    });

    await s3.send(
      new PutObjectCommand({
        Bucket: config.iiifBucket,
        Key: iiifObjectKey,
        Body: png1x1,
        ContentType: 'image/png',
      }),
    );

    const head = await s3.send(
      new HeadObjectCommand({
        Bucket: config.iiifBucket,
        Key: iiifObjectKey,
      }),
    );

    expect(head.ContentLength).toBe(png1x1.length);
  });

  test('Strapi accepts image upload', async () => {
    const api = await request.newContext({
      baseURL: config.strapiUrl,
      extraHTTPHeaders: {
        Authorization: `Bearer ${config.strapiUploadToken}`,
      },
    });

    const response = await api.post('/api/upload', {
      multipart: {
        files: {
          name: `validation-${runId}.png`,
          mimeType: 'image/png',
          buffer: png1x1,
        },
      },
    });

    expect(response.ok(), await response.text()).toBeTruthy();
    const body = await response.json();
    expect(Array.isArray(body)).toBeTruthy();
    expect(body[0]).toHaveProperty('url');
    await api.dispose();
  });

  test('Cantaloupe serves IIIF info.json for uploaded object', async () => {
    const api = await request.newContext();
    const id = encodedIiifIdentifier(iiifObjectKey);
    const response = await api.get(joinUrl(config.cantaloupeUrl, `/iiif/2/${id}/info.json`));

    expect(response.ok(), await response.text()).toBeTruthy();
    const body = await response.json();
    expect(body).toHaveProperty('@id');
    expect(body).toHaveProperty('width');
    expect(body).toHaveProperty('height');
    await api.dispose();
  });

  test('Cantaloupe generates IIIF thumbnail', async () => {
    const api = await request.newContext();
    const id = encodedIiifIdentifier(iiifObjectKey);
    const response = await api.get(joinUrl(config.cantaloupeUrl, `/iiif/2/${id}/full/!200,200/0/default.jpg`));

    expect(response.ok(), await response.text()).toBeTruthy();
    expect(response.headers()['content-type']).toContain('image');
    expect((await response.body()).length).toBeGreaterThan(0);
    await api.dispose();
  });

  test('Next.js frontend is available', async () => {
    const api = await request.newContext();
    const response = await api.get(config.frontendUrl);

    expect(response.ok(), await response.text()).toBeTruthy();
    expect(response.headers()['content-type']).toContain('text/html');
    await api.dispose();
  });
});
