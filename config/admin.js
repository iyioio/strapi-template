module.exports = ({ env }) => ({
  auth: {
    secret: env('ADMIN_JWT_SECRET', '6d6ca9e8e8cc3ddeb370073d101cc596'),
  },
});
