module.exports = ({ env }) => ({
  connection: {
    client: env('DATABASE_TYPE', 'mysql'),
    connection: {
      host: env('DATABASE_HOST', '127.0.0.1'),
      port: env.int('DATABASE_PORT', 0)||undefined,
      database: env('DATABASE_NAME', 'cms'),
      user: env('DATABASE_USERNAME', 'sqluser'),
      password: env('DATABASE_PASSWORD', 'SQLPasss'),
      ssl: env.bool('DATABASE_SSL', false),
    },
  },
});
