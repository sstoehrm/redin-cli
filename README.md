# redin-cli

Project manager for [redin](https://github.com/sstoehrm/redin) — a re-frame inspired desktop UI framework.

## Install

```bash
curl -sL https://raw.githubusercontent.com/sstoehrm/redin-cli/main/install.sh | bash
```

Requires [Babashka](https://babashka.org/).

## Usage

### Create a Fennel project

```bash
redin-cli new-fnl my-app
cd my-app
./redinw --dev main.fnl
```

### Create a Lua project

```bash
redin-cli new-lua my-app
cd my-app
./redinw --dev main.lua
```

Both create a project with:
- `.redin/` — pinned redin binary and runtime (gitignored)
- `redinw` — wrapper script (committed to git)
- `main.fnl` or `main.lua` — starter counter app with canvas background
- `flsproject.fnl` (Fennel) or `.luarc.json` (Lua) — linter config

### Upgrade to native (Odin)

For apps that need raw Raylib access (3D, shaders, custom renderers):

```bash
cd my-app
redin-cli upgrade-to-native
cd native && ./build.sh
./redinw --dev main.fnl
```

This copies the Odin host source into `native/` with an example canvas provider. You can write Odin code, build a custom binary, and `redinw` will use it automatically.

### Update redin version

```bash
# Update to latest
redin-cli update

# Update to specific version
redin-cli update v0.2.0
```

### Check latest version

```bash
redin-cli latest
```

## How it works

Each project has its own `.redin/` folder containing the redin binary and runtime from a specific release. The `redinw` wrapper script runs the local binary. No global redin installation needed.

`.redin/` is gitignored. `redinw` is committed. When a teammate clones the repo, they run `redin-cli update` to download the pinned version.

### Native development

After `upgrade-to-native`, the `native/` directory contains a full copy of the Odin host source plus your `providers.odin`. Build with `native/build.sh`. The `redinw` wrapper prefers `build/redin` over `.redin/redin` when available.

To update the framework source after a redin update, re-run `upgrade-to-native`. It preserves your `providers.odin` and any other user-created files.
