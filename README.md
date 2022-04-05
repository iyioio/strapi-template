# Strapi-template
A Strapi Template. Fork and configure

## Local setup
``` sh

# Install npm packages
npm i


# Setup local env using 1 of 2 options


# Option 1 - MySQL running in docker
npm run setup-local-with-docker

# Option 2 - Local MySQL instance
npm run setup-local-no-docker


# Start Strapi in develop mode
npm run develop

```

<br/><br/>

## GCloud Setup

1. Create a new GCloud project

2. Create a new Postgress Cloud SQL instance

3. Create a new service account
  - App Engine Admin
  - Cloud Build Editor
  - Cloud Scheduler Admin
  - Secret Manager Secret Accessor
  - Service Account User
  - Storage Admin

4. Create a new key for the service account

5. Create a new GitHub actions secret named "GCP_SA_KEY" and set it's value to the value of the service account key

6. Replace placeholders in gc-config.json

7. Run the apply config script
``` sh
npm run apply-config
```

8. Run the GCloud setup script
``` sh
npm run gcloud-setup
```

<br/><br/>

## Deploying to GCloud
After completing **GCloud Setup** deploying is done by simply pushing changes to the **deploy** branch

<br/>
<br/>
<br/>

---

Below is the default Strapi README

---

# 🚀 Getting started with Strapi

Strapi comes with a full featured [Command Line Interface](https://docs.strapi.io/developer-docs/latest/developer-resources/cli/CLI.html) (CLI) which lets you scaffold and manage your project in seconds.

### `develop`

Start your Strapi application with autoReload enabled. [Learn more](https://docs.strapi.io/developer-docs/latest/developer-resources/cli/CLI.html#strapi-develop)

```
npm run develop
# or
yarn develop
```

### `start`

Start your Strapi application with autoReload disabled. [Learn more](https://docs.strapi.io/developer-docs/latest/developer-resources/cli/CLI.html#strapi-start)

```
npm run start
# or
yarn start
```

### `build`

Build your admin panel. [Learn more](https://docs.strapi.io/developer-docs/latest/developer-resources/cli/CLI.html#strapi-build)

```
npm run build
# or
yarn build
```

## ⚙️ Deployment

Strapi gives you many possible deployment options for your project. Find the one that suits you on the [deployment section of the documentation](https://docs.strapi.io/developer-docs/latest/setup-deployment-guides/deployment.html).

## 📚 Learn more

- [Resource center](https://strapi.io/resource-center) - Strapi resource center.
- [Strapi documentation](https://docs.strapi.io) - Official Strapi documentation.
- [Strapi tutorials](https://strapi.io/tutorials) - List of tutorials made by the core team and the community.
- [Strapi blog](https://docs.strapi.io) - Official Strapi blog containing articles made by the Strapi team and the community.
- [Changelog](https://strapi.io/changelog) - Find out about the Strapi product updates, new features and general improvements.

Feel free to check out the [Strapi GitHub repository](https://github.com/strapi/strapi). Your feedback and contributions are welcome!

## ✨ Community

- [Discord](https://discord.strapi.io) - Come chat with the Strapi community including the core team.
- [Forum](https://forum.strapi.io/) - Place to discuss, ask questions and find answers, show your Strapi project and get feedback or just talk with other Community members.
- [Awesome Strapi](https://github.com/strapi/awesome-strapi) - A curated list of awesome things related to Strapi.

---
