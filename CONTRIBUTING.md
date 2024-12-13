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

### Config the Remapping

We use different remapping.txt 

```txt
@redprint-core/=src/
@redprint-deploy/=script/
@redprint-test/=test/

@redprint-forge-std/=lib/forge-std/src/
@redprint-openzeppelin/=lib/openzeppelin-4_7_3/contracts
@redprint-openzeppelin-upgradeable/=lib/openzeppelin-upgradeable-4_7_3/contracts
@redprint-safe-contracts/=lib/safe-smart-account/contracts/
@redprint-lib-keccak/=lib/lib-keccak/contracts/lib/
@redprint-solady/=node_modules/solady/src/
```

or using from installed package `redprint-forge`

```txt
@redprint-core/=node_modules/redprint-forge/src
@redprint-deploy/=node_modules/redprint-forge/script
@redprint-test/=node_modules/test/
@redprint-forge-std/=node_modules/redprint-forge/lib/forge-std/src
@redprint-openzeppelin/=node_modules/redprint-forge/lib/openzeppelin-4_7_3/contracts
@redprint-openzeppelin-upgradeable/=node_modules/redprint-forge/lib/openzeppelin-upgradeable-4_7_3/contracts
@redprint-safe-contracts/=node_modules/redprint-forge/lib/safe-smart-account/contracts
@redprint-lib-keccak/=node_modules/redprint-forge/lib/lib-keccak/contracts/lib/
@redprint-solady/=node_modules/redprint-forge/lib/solady/src/
```

