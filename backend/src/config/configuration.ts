export default () => ({
  port: parseInt(process.env.PORT ?? '3000', 10),
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN ?? '30d',
  },
  watchmode: {
    apiKey: process.env.WATCHMODE_API_KEY,
    baseUrl: process.env.WATCHMODE_BASE_URL ?? 'https://api.watchmode.com/v1',
    country: process.env.CATALOG_SYNC_COUNTRY ?? 'ES',
  },
  catalogSyncCron: process.env.CATALOG_SYNC_CRON ?? '0 3 * * *',
});
