## Quick Installation


### Scaffolding

```bash
nvm use v20.12.2
```

Integrating tailwind:

https://tailwindcss.com/docs/guides/sveltekit

Installing dependencies :

```bash
pnpm add -D @openzeppelin/contracts@v4.9.4
pnpm add -D forge-std@github:foundry-rs/forge-std#v1.8.1
pnpm add -D clones-with-immutable-args@v1.0.0
```

### Publishing

```bash
git add .
git commit -am "v0.0.5"
git push -u origin main
git tag v0.0.5 main
git push origin tag v0.0.5
```

DONT forget to add secret env `NPM_AUTH_TOKEN` at [repo](https://github.com/Ratimon/solid-grinder/settings/secrets/actions)