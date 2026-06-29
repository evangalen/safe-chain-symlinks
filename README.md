# `safe-chain-symlinks`
This repository offers an enhanced installation of the [Aikido Safe-Chain](https://github.com/AikidoSec/safe-chain)
, providing malware protection for the npm and PyPI (Python) ecosystems.

**NOTE**: safe-chain-symlinks only supports macOS and Linux, and only supports Bash and Zsh shells.  
          Use the standard Aikido Safe-Chain for Windows support or other shells (Fish) on macOS/Linux.

## Table of Contents
<!-- TOC -->
* [`safe-chain-symlinks`](#safe-chain-symlinks)
  * [Table of Contents](#table-of-contents)
  * [Short intro to Safe-Chain](#short-intro-to-safe-chain)
  * [Prerequisites](#prerequisites)
  * [Corepack, Volta and Yarn support](#corepack-volta-and-yarn-support)
  * [Installation](#installation)
    * [Creating a `.env` file (when none exists)](#creating-a-env-file-when-none-exists)
    * [Committed `.env` file in forked repo](#committed-env-file-in-forked-repo)
    * [Overriding contents of `VERSION.txt` in forked repo](#overriding-contents-of-versiontxt-in-forked-repo)
    * [Installation on local development machine](#installation-on-local-development-machine)
    * [Installation warnings due to insufficient access rights](#installation-warnings-due-to-insufficient-access-rights)
    * [Installation for CI/CD environment](#installation-for-cicd-environment)
      * [Auto `safe-chain-verify` in CI/CD installation](#auto-safe-chain-verify-in-cicd-installation)
      * [Installing in CI/CD mode](#installing-in-cicd-mode)
      * [Detailed CI/CD instructions on Safe-Chain README](#detailed-cicd-instructions-on-safe-chain-readme)
  * [Uninstallation](#uninstallation)
  * [Updating the installation](#updating-the-installation)
    * [Preventing unnecessary updating](#preventing-unnecessary-updating)
    * [Enforcing an update](#enforcing-an-update)
    * [Controlling updates through your own `safe-chain-symlinks` fork](#controlling-updates-through-your-own-safe-chain-symlinks-fork)
  * [Limitations of standard Aikido Safe-Chain installation](#limitations-of-standard-aikido-safe-chain-installation)
  * [Enhancing the standard Aikido Safe-Chain installation](#enhancing-the-standard-aikido-safe-chain-installation)
    * [Symlinked wrappers](#symlinked-wrappers)
    * [Updating symlinked wrappers once installed](#updating-symlinked-wrappers-once-installed)
    * [Auto `safe-chain-verify`](#auto-safe-chain-verify)
    * [Terminal-only protection](#terminal-only-protection)
  * [Known issues](#known-issues)
<!-- TOC -->

## Short intro to Safe-Chain
Safe-Chain, from Aikido Security, is an open-source malware protection solution for the npm and PyPI (Python) ecosystems
that "blocks downloads before malicious code reaches your machine".

Additionally, Safe-Chain enforces a "Minimum package age" (aka Release cooldown) of 48 hours for newly
released packages.\  
This gives Aikido Security more than enough time to add malicious package versions to their malware lists:
- npm: https://malware-list.aikido.dev/malware_predictions.json
- PyPI: https://malware-list.aikido.dev/malware_pypi.json

Last but not least... malicious npm packages are usually unpublished within this 48-hour window.

More information about how Safe-Chain works can be found in the
["How it works"](https://github.com/AikidoSec/safe-chain#how-it-works) section of the Safe-Chain repository.

## Prerequisites
The safe-chain-symlinks enhanced installation has the following prerequisites:
- macOS or Linux (or Windows Subsystem for Linux on Windows)
- Bash or Zsh shell
- Node Version Manager (NVM) must be used exclusively to manage Node installations
  - Other installation methods (e.g., `brew install node`) are **not supported**

## Corepack, Volta and Yarn support
Corepack and Volta also use symlinks, similar to safe-chain-symlinks, and may therefore not work as expected.

To use Yarn without Corepack, install Yarn Classic (v1.x) and then upgrade to modern Yarn (Berry):
```shell
npm install -g yarn
yarn set version berry
```

## Installation

### Creating a `.env` file (when none exists)
Prior to installation, ensure that a `.env` file exists in the root of the safe-chain-symlinks repository.

If it does not exist, create one by copying `.env.example`:
```shell
$ [ ! -e .env ] && cp .env.example .env || echo ".env file already exist!"
```

After creating the `.env` file, fill in the following values:

- `safe-chain-version`: version of Aikido Safe-Chain
- `install-safe-chain-dot-sh-hash`: hash of `install-safe-chain.sh`, obtained from the [Safe-Chain releases page](https://github.com/AikidoSec/safe-chain/releases)
- `uninstall-safe-chain-dot-sh-hash`: hash of `uninstall-safe-chain.sh`, also from the [Safe-Chain releases page](https://github.com/AikidoSec/safe-chain/releases)

### Committed `.env` file in forked repo
When you're using a forked repo of the original
[`safe-chain-symlinks` GitHub repo](https://github.com/evangalen/safe-chain-symlinks), you can choose to commit
the `.env` file in the forked repo.

This would then allow you to control which version of Aikido Safe-Chain is installed and prevents the friction of
manually having to copy & paste hashes for both `.sh` files from the Releases page of safe-chain GitHub repo.

### Overriding contents of `VERSION.txt` in forked repo
Using your own forked repo, you could combine a committed `.env` file (see above) with manually overriding &
commiting the contents of the `VERSION.txt`.

This forked repo approach could be a great for [Updating the installation](#updating-the-installation), because:
 - updating and commiting your own contents of the `VERSION.txt` gives you control when to update
 - committing the `.env` file allows to specify which version of Aikido Safe-Chain will be installed

### Installation on local development machine
To install `safe-chain-symlinks` including Aikido Safe-Chain, execute `./bin/safe-chain-symlinks install` in the
terminal:

```shell
$ ./bin/safe-chain-symlinks install
```
```
safe-chain-symlinks (version: …; Aikido Safe-Chain: N/A)

▶  Installing Aikido Safe-Chain including "safe-chain-symlinks" enhancements

⚒  Downloading install script for Aikido Safe-Chain (compatible with legacy Node versions)
⚒  Downloading uninstall script for Aikido Safe-Chain (compatible with legacy Node versions)
⚒  Executing downloaded install script for Aikido Safe-Chain

[INFO] Fetching latest release version...
[INFO] Installing safe-chain …
[INFO] Detected platform: linuxstatic-x64
[INFO] Creating installation directory: /home/a-user/.safe-chain/bin
[INFO] Downloading from: https://github.com/AikidoSec/safe-chain/releases/download/…/safe-chain-linuxstatic-x64
[INFO] Checksum verified.
[INFO] Binary installed to: /home/a-user/.safe-chain/bin/safe-chain
[INFO] Running safe-chain setup...
Setting up shell aliases. This will wrap safe-chain around npm, npx, yarn, pnpm, pnpx, rush, rushx, bun, bunx, uv, uvx, pip, pip3, poetry, python, python3, pipx, and pdm commands.

Detected 2 supported shell(s): Zsh, Bash.
- Zsh: Setup successful
- Bash: Setup successful

Please restart your terminal to apply the changes.

⚒  Moving downloaded `uninstall-safe-chain.sh` to /home/a-user/.safe-chain/scripts

⚒  Setting up wrappers for NVM-managed Node v20.19.0
⚒  safe-chain-symlinks: Creating /home/a-user/.nvm/versions/node/v20.19.0/bin-originals directory to keep originals of wrapped binaries
⚒  safe-chain-symlinks: Setting up `npx` wrapper in /home/a-user/.nvm/versions/node/v20.19.0/bin (keeping original binary in /home/a-user/.nvm/versions/node/v20.19.0/bin-originals)
⚒  safe-chain-symlinks: Setting up `npm` wrapper in /home/a-user/.nvm/versions/node/v20.19.0/bin (keeping original binary in /home/a-user/.nvm/versions/node/v20.19.0/bin-originals)

⚒  Setting up wrappers for NVM-managed Node v24.16.0
⚒  safe-chain-symlinks: Creating /home/a-user/.nvm/versions/node/v24.16.0/bin-originals directory to keep originals of wrapped binaries
⚒  safe-chain-symlinks: Setting up `npx` wrapper in /home/a-user/.nvm/versions/node/v24.16.0/bin (keeping original binary in /home/a-user/.nvm/versions/node/v24.16.0/bin-originals)
⚒  safe-chain-symlinks: Setting up `npm` wrapper in /home/a-user/.nvm/versions/node/v24.16.0/bin (keeping original binary in /home/a-user/.nvm/versions/node/v24.16.0/bin-originals)

⚒  Setting up wrappers for `PATH` entries other than NVM-managed Node versions
⚒  safe-chain-symlinks: Setting up `pnpm` wrapper in /home/a-user/.local/share/pnpm/bin (keeping original binary in /home/a-user/.local/share/pnpm/bin-originals)
⚒  safe-chain-symlinks: Setting up `pnpx` wrapper in /home/a-user/.local/share/pnpm/bin (keeping original binary in /home/a-user/.local/share/pnpm/bin-originals)
⚒  safe-chain-symlinks: Setting up `bun` wrapper in /home/a-user/.bun/bin (keeping original binary in /home/a-user/.bun/bin-originals)
⚒  safe-chain-symlinks: Setting up `bunx` wrapper in /home/a-user/.bun/bin (keeping original binary in /home/a-user/.bun/bin-originals)
⚠  safe-chain-symlinks: Failed to setup `pip` wrapper in /usr/bin due to insufficient access rights
⚠  safe-chain-symlinks: Failed to setup `pip3` wrapper in /usr/bin due to insufficient access rights
⚠  safe-chain-symlinks: Failed to setup `python3` wrapper in /usr/bin due to insufficient access rights
⚠  safe-chain-symlinks: Failed to setup `pipx` wrapper in /usr/bin due to insufficient access rights
⚠  safe-chain-symlinks: Failed to setup `pip` wrapper in /bin due to insufficient access rights
⚠  safe-chain-symlinks: Failed to setup `pip3` wrapper in /bin due to insufficient access rights
⚠  safe-chain-symlinks: Failed to setup `python3` wrapper in /bin due to insufficient access rights
⚠  safe-chain-symlinks: Failed to setup `pipx` wrapper in /bin due to insufficient access rights

⚒  Adding `source "…/scripts/init-posix.sh"` entry to /home/a-user/.bashrc
→  Please restart your terminal to apply the changes.

⚒  Adding `source "…/scripts/init-posix.sh"` entry to /home/a-user/.zshrc
→  Please restart your terminal to apply the changes.

▣  Installation completed of Aikido Safe-Chain … including "safe-chain-symlinks" enhancements (version: …)
```

### Installation warnings due to insufficient access rights
During installation, you may encounter warnings such as:
```
⚠ safe-chain-symlinks: Failed to set up … due to insufficient access rights
```

This typically occurs when a package manager binary is installed system-wide (e.g., Python binaries such as `python`,
`pip`, etc.).\
Even if a symlink wrapper cannot be created, Safe-Chain still provides terminal-only protection:
```shell
$ pip3 --version
```
```
⚠  safe-chain-symlinks: Terminal‑only protection — `pip3` is only protected inside the terminal by Aikido Safe‑Chain (version: …; symlinks: …)
pip 22.0.2 from /usr/lib/python3/dist-packages/pip (python 3.10)
```

**NOTE**: the automatic `safe-chain-verify` and the `⚠  safe-chain-symlinks: Terminal‑only protection — `
message is actually an addition of `safe-chain-symlinks` to the standard Safe-Chain installation.

### Installation for CI/CD environment
For CI/CD usage, Aikido Safe-Chain provides a separate installation method that uses path-shadowing wrapper shell
scripts instead of shell functions.

These scripts are located in the `shims` directory of the Safe-Chain installation.

Unlike local installations, the CI/CD setup does **not** replace package manager binaries with symlinks.\
Instead, safe-chain-symlinks replaces the Safe-Chain shim scripts with symlinked wrappers:

```shell
$ ls -als ~/.safe-chain/shims
```
```
total 80
4 drwxrwxr-x 2 a-user a-user 4096 feb 28 10:33 .
4 drwxrwxr-x 7 a-user a-user 4096 feb 28 10:33 ..
4 lrwxrwxrwx 1 a-user a-user  107 feb 28 10:33 bun -> …/scripts/symlinked/package-manager-wrapper.sh
4 lrwxrwxrwx 1 a-user a-user  107 feb 28 10:33 bunx -> …/scripts/symlinked/package-manager-wrapper.sh
4 lrwxrwxrwx 1 a-user a-user  107 feb 28 10:33 npm -> …/scripts/symlinked/package-manager-wrapper.sh
4 lrwxrwxrwx 1 a-user a-user  107 feb 28 10:33 npx -> …/scripts/symlinked/package-manager-wrapper.sh
4 lrwxrwxrwx 1 a-user a-user  107 feb 28 10:33 pdm -> …/scripts/symlinked/package-manager-wrapper.sh
4 lrwxrwxrwx 1 a-user a-user  107 feb 28 10:33 pip -> …/scripts/symlinked/package-manager-wrapper.sh
4 lrwxrwxrwx 1 a-user a-user  107 feb 28 10:33 pip3 -> …/scripts/symlinked/package-manager-wrapper.sh
4 lrwxrwxrwx 1 a-user a-user  107 feb 28 10:33 pipx -> …/scripts/symlinked/package-manager-wrapper.sh
4 lrwxrwxrwx 1 a-user a-user  107 feb 28 10:33 pnpm -> …/scripts/symlinked/package-manager-wrapper.sh
4 lrwxrwxrwx 1 a-user a-user  107 feb 28 10:33 pnpx -> …/scripts/symlinked/package-manager-wrapper.sh
4 lrwxrwxrwx 1 a-user a-user  107 feb 28 10:33 poetry -> …/scripts/symlinked/package-manager-wrapper.sh
4 lrwxrwxrwx 1 a-user a-user  107 feb 28 10:33 python -> …/scripts/symlinked/package-manager-wrapper.sh
4 lrwxrwxrwx 1 a-user a-user  107 feb 28 10:33 python3 -> …/scripts/symlinked/package-manager-wrapper.sh
4 lrwxrwxrwx 1 a-user a-user  107 feb 28 10:33 rush -> …/scripts/symlinked/package-manager-wrapper.sh
4 lrwxrwxrwx 1 a-user a-user  107 feb 28 10:33 rushx -> …/scripts/symlinked/package-manager-wrapper.sh
4 lrwxrwxrwx 1 a-user a-user  107 feb 28 10:33 uv -> …/scripts/symlinked/package-manager-wrapper.sh
4 lrwxrwxrwx 1 a-user a-user  107 feb 28 10:33 uvx -> …/scripts/symlinked/package-manager-wrapper.sh
4 lrwxrwxrwx 1 a-user a-user  107 feb 28 10:33 yarn -> …/scripts/symlinked/package-manager-wrapper.sh
```

#### Auto `safe-chain-verify` in CI/CD installation
The sole reason of `safe-chain-symlinks` to replace the standard CI/CD shims of Safe-Chain with symlinked wrappers is
to do an auto `safe-chain-verify` whenever a package managers is executed, just like with the regular installation:

```shell
$ npm install
```
```
✓  safe-chain-symlinks: Verified `npm` to be protected by Aikido Safe-Chain (version: …; symlinks: …)

changed 1 package in 185ms
```

**NOTE**: for `npm install` to show the verification message, the `shims` directory of the Safe-Chain installation needs
to be on the `PATH`; see the NOTE in the ["Installing in CI/CD mode" section](#installing-in-cicd-mode) below for more
information.

#### Installing in CI/CD mode
To install `safe-chain-symlinks` including Safe-Chain in CI/CD mode use the `--ci` flag:
```shell
$ ./bin/safe-chain-symlinks install --ci
```
```
safe-chain-symlinks (version: …; Aikido Safe-Chain: …)

▶  Installing Aikido Safe-Chain including "safe-chain-symlinks" enhancements

⚒  Downloading install script for Aikido Safe-Chain (compatible with legacy Node versions)
⚒  Downloading uninstall script for Aikido Safe-Chain (compatible with legacy Node versions)
⚒  Executing downloaded install script for Aikido Safe-Chain

[INFO] Fetching latest release version...
[INFO] Installing safe-chain 1.5.10 in ci
[INFO] Detected platform: linuxstatic-x64
[INFO] Creating installation directory: /home/a-user/.safe-chain/bin
[INFO] Downloading from: https://github.com/AikidoSec/safe-chain/releases/download/1.5.10/safe-chain-linuxstatic-x64
[INFO] Checksum verified.
[INFO] Binary installed to: /home/a-user/.safe-chain/bin/safe-chain
[INFO] Running safe-chain setup-ci...
Setting up shell aliases. This will wrap safe-chain around npm, npx, yarn, pnpm, pnpx, rush, rushx, bun, bunx, uv, uvx, pip, pip3, poetry, python, python3, pipx, and pdm commands.

Created 18 Unix shim(s) in /home/a-user/.safe-chain/shims
Created shims in /home/a-user/.safe-chain/shims
Added shims directory to PATH for CI environments.

⚒  Creating /home/a-user/.safe-chain/scripts directory to keep downloaded `uninstall-safe-chain.sh`

⚒  Moving downloaded `uninstall-safe-chain.sh` to /home/a-user/.safe-chain/scripts

⚒  Creating /home/a-user/.safe-chain/shims-originals directory to keep originals of CI/CD shims
⚒  Setting up wrappers for all files in `shims` directory of CI/CD installation of Aikido Safe-Chain

▣  Installation completed of Aikido Safe-Chain … including "safe-chain-symlinks" enhancements (version: …)
```

**NOTE**: some of the messages outputted by the CI/CD installation of Safe-Chain are incorrect (at the time of writing):
- since "Setting up shell aliases" is **not** actually done for a CI/CD installation
- depending on your CI/CD environment the "Added shims directory to PATH for CI environments" message might not be
  correct;
  e.g., for GitLab pipelines you will have to manually add the `shims` directory of the Safe-Chain installation to the
        `PATH`.

#### Detailed CI/CD instructions on Safe-Chain README
Detailed information about installing Safe-Chain for various CI/CD environements can be found in the
["Usage in CI/CD" section](https://github.com/AikidoSec/safe-chain#usage-in-cicd) of the README on the Safe-Chain GitHub repo.

But, instead of executing a
`curl -fsSL https://github.com/AikidoSec/safe-chain/releases/download/`..`/install-safe-chain.sh | sh -s -- --ci`,
first do a `git clone` of the `safe-chain-symlinks` repo and then execute `./bin/safe-chain-symlinks install --ci` in
the root of the cloned Git repo.

## Uninstallation
To uninstall `safe-chain-symlinks` including Aikido Safe-Chain, execute `./bin/safe-chain-symlinks uninstall` in the
terminal:

```shell
$ ./bin/safe-chain-symlinks uninstall
```
```
safe-chain-symlinks (version: …; Aikido Safe-Chain: …)

▶  Unstalling Aikido Safe-Chain including "safe-chain-symlinks" enhancements

⚒  Tearing down wrappers for NVM-managed Node v20.19.0
⚒  Tearing down `npx` wrapper in /home/a-user/.nvm/versions/node/v20.19.0/bin
⚒  Tearing down `npm` wrapper in /home/a-user/.nvm/versions/node/v20.19.0/bin
⚒  Removing /home/a-user/.nvm/versions/node/v20.19.0/bin-originals directory

⚒  Tearing down wrappers for NVM-managed Node v24.16.0
⚒  Tearing down `npx` wrapper in /home/a-user/.nvm/versions/node/v24.16.0/bin
⚒  Tearing down `npm` wrapper in /home/a-user/.nvm/versions/node/v24.16.0/bin
⚒  Removing /home/a-user/.nvm/versions/node/v24.16.0/bin-originals directory

⚒  Tearing down wrappers for `PATH` entries other than NVM-managed Node versions
⚒  Tearing down `pnpm` wrapper in /home/a-user/.local/share/pnpm/bin
⚒  Tearing down `pnpx` wrapper in /home/a-user/.local/share/pnpm/bin
⚒  Tearing down `bun` wrapper in /home/a-user/.bun/bin
⚒  Tearing down `bunx` wrapper in /home/a-user/.bun/bin

⚒  Uninstalling Aikido Safe-Chain using uninstall script (stored during installation in /home/a-user/.safe-chain/scripts/uninstall-safe-chain.sh)

[INFO] Running safe-chain teardown...
Removing shell aliases. This will remove safe-chain aliases for npm, npx, yarn, pnpm, pnpx, rush, rushx, bun, bunx, uv, uvx, pip, pip3, poetry, python, python3, pipx, and pdm commands.

Detected 2 supported shell(s): Zsh, Bash.
- Zsh: Teardown successful
- Bash: Teardown successful

Please restart your terminal to apply the changes.
- Scripts: Removed successfully
[INFO] Removing installation directory /home/a-user/.safe-chain

⚒  Removing `source "…/scripts/init-posix.sh"` (including surplus surrounding empty lines) from /home/a-user/.bashrc
→  Please restart your terminal to apply the changes.

⚒  Removing `source "…/scripts/init-posix.sh"` (including surplus surrounding empty lines) from /home/a-user/.zshrc
→  Please restart your terminal to apply the changes.

▣  Uninstallation completed.
```

## Updating the installation
The `safe-chain-symlinks` executable, besides `install` and `uninstall` arguments, also supports an `update`.

An `update` effectively does nothing more than:
 - first, a `safe-chain-symlinks uninstall` to teardown the symlinked wrappers and to uninstall Safe-Chain
 - then, a `git pull` to update the `safe-chain-symlinks` repo
 - finally, a `safe-chain-symlinks install`

### Preventing unnecessary updating
Prior to the actual updating, `safe-chain-symlinks update` first checks if updating is necessary by:
 - checking if contents of local `VERSION.txt` file differs with the remote `VERSION.txt` file
 - checking if the version of installed Aikido Safe-Chain differs from the `safe-chain-version` entry in the `.env` file
   in the root of the repo

When both the `safe-chain-symlinks` version and Aikido Safe-Chain version are already up-to-date, then
`safe-chain-symlinks update` skips the update:
```shell
$ safe-chain-symlinks update
safe-chain-symlinks (version: …; Aikido Safe-Chain: …)

✓  Skipped update, since both Aikido Safe-Chain and safe-chain-symlinks are already up-to-date.
   Use `--force` to enforce an update (e.g., to reinstall currently installed version of Aikido Safe-Chain).
```

Alternatively, `safe-chain-symlinks update` versions checks might also fail when the remote `VERSION.txt` could not be
fetched:
```shell
$ safe-chain-symlinks update
```
```
safe-chain-symlinks (version: …; Aikido Safe-Chain: …)

⊘  Could not determine if you're using an up-to-date "safe-chain-symlinks" repo.
   Ensure you have the connectivity to do a `git fetch` or alternatively suppress this error using `--force`.
```

### Enforcing an update
Although typically you would want to execute `safe-chain-symlinks update` when there's actually a version update, you
might want to enforce executing an update using the `--force` argument:
```shell
$ safe-chain-symlinks update --force
```

### Controlling updates through your own `safe-chain-symlinks` fork
To prevent inconvenient "are already up-to-date" messages while executing `safe-chain-symlinks update` you could also
choose to fork `safe-chain-symlinks`:
 - and, use a [Committed `.env` file in forked repo](#committed-env-file-in-forked-repo)
 - combined with [Overriding contents of `VERSION.txt` in forked repo](#overriding-contents-of-versiontxt-in-forked-repo)

## Limitations of standard Aikido Safe-Chain installation
The standard Safe-Chain installation is aimed for Terminal‑only usage, and only offers malware protection in case a
supported package manager is used **directly** inside the Terminal:
```shell
$ npm safe-chain-verify
```
```
OK: Safe-chain works!
```

But, when a package manager is **not** directly used from the Terminal, then Safe-Chain no longer works:
```shell
$ echo -e '#!/usr/bin/env bash\nnpm safe-chain-verify' > /tmp/npm-safe-chain-verify-from-shell-script.sh
$ chmod u+x /tmp/npm-safe-chain-verify-from-shell-script.sh 
$ /tmp/npm-safe-chain-verify-from-shell-script.sh 
```
```
Unknown command: "safe-chain-verify"

To see a list of supported npm commands, run:
  npm help
```

Additionally, Safe-Chain does **not** offer malware protection when a package manager binary is executed instead of its
shell function wrapper:
```shell
$ NODE_BIN_DIR="$(dirname "$(command -v node)")"
$ "$NODE_BIN_DIR/npm" safe-chain-verify
```
```
Unknown command: "safe-chain-verify"

To see a list of supported npm commands, run:
  npm help
```

## Enhancing the standard Aikido Safe-Chain installation

### Symlinked wrappers
When Safe-Chain is installed via `safe-chain-symlinks`, the built-in Safe-Chain wrappers using shell functions are
augmented with other wrappers that use symlinked shell scripts.

During the installation a scan for binaries of supported package manager is done:
 - inside the `bin` directory of every [NVM](https://github.com/nvm-sh/nvm)-managed Node version
 - inside the directory of every entry of the `PATH` environment variable (e.g., `usr/bin` and `$HOME/.local/bin`)

When supported package managers (e.g., `npm` and `npx`) are found inside a (e.g., `bin`) directory):
 - first the original binaries of the package managers are be moved into a sibling directory with `-originals` postfix;
   e.g. the `npm` and `npx`  are moved to a newly created `bin-originals` sibling directory
 - then symlinked wrappers are created for every supported package manager
 
For instance, the `npm` and `npx` binaries of a NVM-managed Node version will be replaced with symlinked wrappers:
```shell
$ NODE_DIR="$(dirname "$(command -v node)")/.."
$ ls -als "$NODE_DIR/bin"
```
```
total 120568
     4 drwxr-xr-x 2 a-user a-user      4096 feb 28 12:56 .
     4 drwxrwxr-x 7 a-user a-user      4096 feb 28 12:56 ..
     0 lrwxrwxrwx 1 a-user a-user        45 feb 28 02:04 corepack -> ../lib/node_modules/corepack/dist/corepack.js
120552 -rwxr-xr-x 1 a-user a-user 123438592 feb 28 02:03 node
     4 lrwxrwxrwx 1 a-user a-user       107 feb 28 12:56 npm -> …/scripts/symlinked/package-manager-wrapper.sh
     4 lrwxrwxrwx 1 a-user a-user       107 feb 28 12:56 npx -> …/scripts/symlinked/package-manager-wrapper.sh
```

Whereas, the original `npm` and `npx` binaries are moved to an …`-originals` sibling directory of the `bin` directory:
```shell
$ NODE_DIR="$(dirname "$(command -v node)")/.."
$ ls -als "$NODE_DIR/bin-originals"
```
```
total 8
4 drwxrwxr-x 2 a-user a-user 4096 feb 28 14:54 .
4 drwxrwxr-x 7 a-user a-user 4096 feb 28 13:39 ..
0 lrwxrwxrwx 1 a-user a-user   38 feb 28 14:54 npm -> ../lib/node_modules/npm/bin/npm-cli.js
0 lrwxrwxrwx 1 a-user a-user   38 feb 28 14:54 npx -> ../lib/node_modules/npm/bin/npx-cli.js
```

### Updating symlinked wrappers once installed
Once installed, `safe-chain-symlinks` goes to great lengths to automatically add symlinked wrappers (and sometimes also
automatically removes them) :
- after installing a Node version with Node Version Manager 
- after executing a magic `curl `.. command for a whitelisted installation shell script (e.g., for `pnpm` and `bun`)
- after using Brew is used to `install`, `upgrade` or `uninstall` a package manager (e.g., for `pnpm` and `bun`)
- after using a supported package manager to upgrade or install another (supported) package manager;\
  e.g., after a `npm install -g npm@latest` or a `npm install -g pnpm`
- when last executed terminal command updated the `PATH` and a new executable package manager binaries were added

Besides the automatic updating for symlinked wrappers, it's also possible to explicitly execute call `update-wrappers`:
```shell
$ safe-chain-symlinks update-wrappers
```

As opposed to iterating every entry of the `PATH` environment variable, `update-wrappers` uses the `which` command to
quickly find out the file paths for each supported packaged manager.

Alternative, `update-wrappers` can also focus on one directory by specifying an argument:
```shell
$ safe-chain-symlinks update-wrappers /some/directory
```

### Auto `safe-chain-verify`
The standard Safe-Chain installation unfortunately does **not** automatically do a `safe-chain-verify` and show
verification message.
Instead, with standard Safe-Chain installation you'll manually have to do a manual `safe-chain-verify` check:

```shell
$ npm safe-chain-verify
```
```
OK: Safe-chain works!
```

But, when using `safe-chain-symlinks` the output of **every** package manager command always start with a verification
message like this:
```shell
$ npm install
```
```
✓  safe-chain-symlinks: Verified `npm` to be protected by Aikido Safe-Chain (version: …; symlinks: …)

changed 1 package in 147ms
```

If for some reason the automatic `safe-chain-verify` check (e.g., `npm safe-chain-verify`) failed, then you'll see
a failure and then the actual package manager command will **not** be executed:
```shell
$ npm install
```
```
⊘  Failed `npm safe-chain-verify` check (Aikido Safe-Chain version: …; symlinks: …)
```

### Terminal-only protection
When directly using a package manager in the terminal, you might get an alternative `safe-chain-verify` verification
message that's actually a warning.
This typically occurs for package managers that are installed system-wide, which typically is the case for the
Python-related binaries `python`, `python3`, `pip` and `pip3`, causing setup of the symlinked wrappers to fail do 
insufficient access rights:

```shell
$ pip3 --version
```
```
⚠  safe-chain-symlinks: Terminal‑only protection — `pip3` is only protected inside the terminal by Aikido Safe‑Chain (version: …; symlinks: …)
pip 22.0.2 from /usr/lib/python3/dist-packages/pip (python 3.10)
```

## Known issues
When running `npm install` or `npm ci`, you may notice that pressing CTRL+C does not behave as expected.\
This appears to be caused by the use of wrapper shell scripts.\
Various workarounds were attempted (e.g., using `exec env` or `trap`), but none fully resolve the issue without introducing new problems.
