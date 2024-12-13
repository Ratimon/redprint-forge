<h1>Keep Optimistic and be OPStack deployer!! </h1>

- [Installation](#installation)
- [What is it for](#what-is-it-for)
- [Quickstart](#quickstart)
- [Contributing](#contributing)
- [Acknowledgement](#acknowledgement)

>[!NOTE]
> You can find our alpha mvp and relevant examples [`here`](https://github.com/Ratimon/redprint-optimism-contracts-examples)

>[!WARNING]
> The code is not audited yet. Please use it carefully in production.


## Installation

1.  Fork `optimism` 's monorepo:

```bash
git clone --depth 1 --branch v1.9.4 https://github.com/ethereum-optimism/optimism.git
``` 

>[!NOTE]
> All OPStack's contracts are based on [`v1.9.4`](https://github.com/ethereum-optimism/optimism/tree/v1.9.4/packages/contracts-bedrock). So, you may just run:

```bash
git clone https://github.com/ethereum-optimism/optimism.git
``` 

2. Enter the working ditectory:

```bash
cd ethereum-optimism/packages/contracts-bedrock
``` 

3. Add the `redprint-forge` using your favorite package manager, e.g., with pnpm:

```bash
pnpm init
``` 
```bash
pnpm add redprint-forge
``` 
```bash
pnpm install
``` 

4. Modify OPStack 's [remapping](https://github.com/ethereum-optimism/optimism/blob/v1.9.4/packages/contracts-bedrock/foundry.toml) as following

```diff

[profile.default]

# Compilation settings
src = 'src'
out = 'forge-artifacts'
script = 'scripts'
optimizer = true
optimizer_runs = 999999
remappings = [
  '@openzeppelin/contracts-upgradeable/=lib/openzeppelin-contracts-upgradeable/contracts',
  '@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts',
  '@openzeppelin/contracts-v5/=lib/openzeppelin-contracts-v5/contracts',
  '@rari-capital/solmate/=lib/solmate',
  '@lib-keccak/=lib/lib-keccak/contracts/lib',
  '@solady/=lib/solady/src',
  'forge-std/=lib/forge-std/src',
  'ds-test/=lib/forge-std/lib/ds-test/src',
  'safe-contracts/=lib/safe-contracts/contracts',
  'kontrol-cheatcodes/=lib/kontrol-cheatcodes/src',
  'gelato/=lib/automate/contracts'
+ '@redprint-core/=src/',
+ '@redprint-deploy/=node_modules/redprint-forge/script',
+ '@redprint-test/=node_modules/redprint-forge/test/',
+ '@redprint-forge-std/=lib/forge-std/src',
+ '@redprint-openzeppelin/=lib/openzeppelin-contracts/contracts',
+ '@redprint-openzeppelin-upgradeable/=lib/openzeppelin-contracts-upgradeable/contracts',
+ '@redprint-safe-contracts/=lib/safe-contracts/contracts',
+ '@redprint-lib-keccak/=lib/lib-keccak/contracts/lib',
+ '@redprint-solady/=lib/solady/src',
]
...
```

>[!TIP]
> We use @redprint-<yourLib>/ as a convention to avoid any naming conflicts with your previously installed libararies ( i.e. `@redprint-forge-std/` vs `@forge-std/`)


5. Copy [`.env`](./.env) and modify as following.

```sh

RPC_URL_localhost=http://localhost:8545

#secret management
MNEMONIC="test test test test test test test test test test test junk"
# local network 's default private key so it is still not exposed
DEPLOYER_PRIVATE_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
DEPLOYER_ADDRESS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8

# script/Config.sol
DEPLOYMENT_OUTFILE=deployments/31337/.save.json
DEPLOY_CONFIG_PATH=deploy-config/hardhat.json
CHAIN_ID=
IMPL_SALT=$(openssl rand -hex 32)
STATE_DUMP_PATH=
SIG=
DEPLOY_FILE=
DRIPPIE_OWNER_PRIVATE_KEY=9000

# deploy-Config
GS_ADMIN_ADDRESS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
GS_BATCHER_ADDRESS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
GS_PROPOSER_ADDRESS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
GS_SEQUENCER_ADDRESS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
L1_RPC_URL=http://localhost:8545
```

6. Copy a set of deploy scripts: 

```
cp node_modules/redprint-forge/script/example/* scripts/
```
Copy a test suite:
```
cp node_modules/redprint-forge/test/example/DeployAll.t.sol test/
```

7. Compile and run test:

```
forge b
```
```
forge test -vvvv --match-path test/DeployAll.t.sol
```


## What Is It For

One of our Swiss army knife toolset: **redprint-forge** is a developer-friendly framework/library in solidity to modify & deploy OPStack ’s contracts in a modular style.

The features include:

- Type-safe smart contract deployment

- Re-usable  smart contract deployment and testing pipeline

- Standardized framework, minimizing developer mistake and enhancing better security

- All-Solidity-based so no context switching, no new scripting syntax in other languages

- Tx Management via Safe Smart Contract Deploy Script

Together with [`Redprint Wizard UI`](https://github.com/Ratimon/redprint-wizard), which is a code generator/ interactive playground oriented for OPStack development, it does not only help novice developers to deploy OPStack's smart contracts to deploy on OP mainnet, but also help them to use generated deployment script in their own projects.


## Quickstart

### Tx Management Via Safe-Multisig

You can write solidity script, then execute it from command-line in order to make any smart contract calls, or send transactions from your own safe multi-sig wallet.

You can access both [`_upgradeAndCallViaSafe`](https://github.com/Ratimon/redprint-forge/blob/main/script/safe-management/SafeScript.sol#L27) and [`_callViaSafe`](https://github.com/Ratimon/redprint-forge/blob/main/script/safe-management/SafeScript.sol#L23) easily by inheriting and using from  in `redprint-forge` module ’s parent contract [`SafeScript`](https://github.com/Ratimon/redprint-forge/blob/main/script/safe-management/SafeScript.sol).
 
#### Call and Upgrade Proxy Contract

Let’s see a practical example when initializing one of OPStack's proxy contract ( eg. [`ProtocolVersions`](https://github.com/Ratimon/redprint-forge/blob/main/src/L1/ProtocolVersions.sol) ) by calling [`_upgradeAndCallViaSafe`](https://github.com/Ratimon/redprint-forge/blob/main/script/safe-management/SafeScript.sol#L27C1-L28C1):

```ts

/** ... */

// `redprint-forge` 's core engine
import { SafeScript} from "@redprint-deploy/safe-management/SafeScript.sol";

/** ... */

contract DeployAndInitializeProtocolVersionsScript is DeployScript, SafeScript {

    /** ... */

    function initializeProtocolVersions() public {
      console.log("Upgrading and initializing ProtocolVersions proxy");

      /** ... */

      address proxyAdmin = deployer.mustGetAddress("ProxyAdmin");
      address safe = deployer.mustGetAddress("SystemOwnerSafe");

      /** ... */

      _upgradeAndCallViaSafe({
          _proxyAdmin: proxyAdmin,
          _safe: safe,
          _owner: owner,
          _proxy: payable(protocolVersionsProxy),
          _implementation: protocolVersions,
          _innerCallData: abi.encodeCall(
              ProtocolVersions.initialize,
              (
                  finalSystemOwner,
                  ProtocolVersion.wrap(requiredProtocolVersion),
                  ProtocolVersion.wrap(recommendedProtocolVersion)
              )
          )
      });
      /** ... */
    }

}

```

>[!NOTE]
> You can the see full example here: [`03B_DeployAndInitializeProtocolVersions.s.sol`](https://github.com/Ratimon/redprint-optimism-contracts-examples/blob/main/script/203B_DeployAndInitializeProtocolVersions.s.sol)

#### Call to Any Contract with arbitrary data

Let’s see another example at [`SafeScript`](https://github.com/Ratimon/redprint-forge/blob/main/script/safe-management/SafeScript.sol) itselfs. Our internal function just calls [`_callViaSafe`](https://github.com/Ratimon/redprint-forge/blob/main/script/safe-management/SafeScript.sol#L23):

```ts
/** ... */

abstract contract SafeScript {

  /** ... */

  function _upgradeAndCallViaSafe( address _owner, address _proxyAdmin, address _safe, address _proxy, address _implementation, bytes memory _innerCallData) internal {

      bytes memory data =
          abi.encodeCall(ProxyAdmin.upgradeAndCall, (payable(_proxy), _implementation, _innerCallData));

      Safe safe = Safe(payable(_safe));
      _callViaSafe({ _safe: safe, _owner: _owner, _target: _proxyAdmin, _data: data });
  }

  /** ... */

}
```

## Contributing

We are currently still in an experimental phase leading up to a first audit and would love to hear your feedback on how we can improve `Reprint`.

If you want to say **thank you** or/and support active development of redprint-forge:

- Add a [GitHub Star](https://github.com/Ratimon/redprint-forge) to the
  project.
- Tweet about **redprint**.
- Write interesting articles about the project on
  [Medium](https://medium.com/), or your personal blog.
- Keep Optimistic !!

## Acknowledgement

This project would not have been possible to build without the advanced iniatiative from opensource software including  [forge-deploy](https://github.com/wighawag/forge-deploy), so we are deeply thankful for their contributions in our web3 ecosystem.

If we’ve overlooked anyone, please open an issue so we can correct it. While we always aim to acknowledge the inspirations and code we utilize, mistakes can happen in a team setting, and a reference might unintentionally be missed.