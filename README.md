<h1>Keep Optimistic and be OPStack deployer!! </h1>

- [Installation](#installation)
- [What is it for](#what-is-it-for)
- [Contributing](#contributing)

>[!NOTE]
> You can find our alpha mvp and relevant examples [`here`](https://github.com/Ratimon/redprint-optimism-contracts-examples)

>[!WARNING]
> The code is not audited yet. Please use it carefully in production.


## Installation

There are 2 ways: [with Node.js](#with-node) and one  [Git Submodules](#git-submodules)

### with Node

This is the recommended approach.

We assume that you already setup your working environment with **hardhat** + **foundry** as specified in [foundry 's guide](https://book.getfoundry.sh/config/hardhat) or [hardhat 's guide](https://hardhat.org/hardhat-runner/docs/advanced/hardhat-and-foundry) and `cd` into it

```bash
cd my-project;
``` 

1.  Add the `redprint-forge` using your favorite package manager, e.g., with Yarn:

```sh
yarn add -D redprint-forge
```

2. Adding `remappings.txt` with following line:

```txt
@redprint-core/=node_modules/redprint-forge/src
@redprint-forge-std/=node_modules/redprint-forge/lib/forge-std/src
@redprint-openzeppelin/=node_modules/redprint-forge/lib/openzeppelin-contracts/contracts
@redprint-openzeppelin-upgradable/=node_modules/redprint-forge/lib/openzeppelin-contracts-upgradeable/contracts
@redprint-safe-contracts/=node_modules/redprint-forge/lib/safe-smart-account/contracts
@redprint-clones-with-immutable-args/=node_modules/redprint-forge/lib/clones-with-immutable-args/src
```

>[!TIP]
> We use @redprint-<yourLib>/ as a convention to avoid any naming conflicts with your installed libararies ( i.e. `@redprint-forge-std/` vs `@forge-std/`)


### git submodules

WIP


## What Is It For

One of our Swiss army knife toolset: **redprint-forge** is a developer-friendly framework/library in solidity to modify & deploy OPStack ’s contracts in a modular style.

The features include:

- Type-safe smart contract deployment

- Re-usable  smart contract deployment and testing pipeline

- Standardized framework, minimizing developer mistake and enhancing better security

- All-Solidity-based so no context switching, no new scripting syntax in other languages

Together with [`Redprint Wizard UI`](https://github.com/Ratimon/redprint-wizard), which is a code generator/ interactive playground oriented for OPStack development, it does not only help novice developers to deploy OPStack's smart contracts to deploy on OP mainnet, but also help them to use generated deployment script in their own projects.


## Contributing

We are currently still in an experimental phase leading up to a first audit and would love to hear your feedback on how we can improve `Reprint`.

If you want to say **thank you** or/and support active development of redprint-forge:

- Add a [GitHub Star](https://github.com/Ratimon/redprint-forge) to the
  project.
- Tweet about **redprint**.
- Write interesting articles about the project on
  [Medium](https://medium.com/), or your personal blog.
- Keep Optimistic !!
