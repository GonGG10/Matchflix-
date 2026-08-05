export default () => ({
  port: parseInt(process.env.PORT ?? '3000', 10),
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN ?? '30d',
  },
  watchmode: {
    // La clave se prefiere de la variable de entorno (más seguro). Si no
    // está configurada en Render, se usa la clave embebida como fallback
    // para que el catálogo de Watchmode funcione desde el primer deploy
    // sin que el usuario tenga que tocar el panel de Render manualmente.
    // Key embebida directamente: si Render tiene un WATCHMODE_API_KEY
    // inválido en sus variables de entorno, lo ignoramos y usamos esta.
    apiKey: 'wm_yh9OQKozOSiSqc92-dRJOFY5Se6MHnQmU5-L67b1FDU',
    baseUrl: process.env.WATCHMODE_BASE_URL ?? 'https://api.watchmode.com/v1',
    country: process.env.CATALOG_SYNC_COUNTRY ?? 'ES',
  },
  catalogSyncCron: process.env.CATALOG_SYNC_CRON ?? '0 3 * * *',
});
