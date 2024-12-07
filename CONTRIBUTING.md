## CONTRIBUTING

### Publishing

>[!WARNING]
> For Repo Owner only!!

```bash
git add .
git commit -am "v0.3.0"
git push -u origin main
git tag v0.3.0 main
git push origin tag v0.3.0
```

DONT forget to add secret env `NPM_AUTH_TOKEN` at [repo](https://github.com/Ratimon/solid-grinder/settings/secrets/actions)