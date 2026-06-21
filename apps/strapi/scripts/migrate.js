const { createStrapi } = require('@strapi/strapi');

async function main() {
  const app = createStrapi({
    appDir: process.cwd(),
    distDir: './dist',
  });

  await app.load();
  await app.destroy();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
