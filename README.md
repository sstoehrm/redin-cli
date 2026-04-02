# redin-cli

Project manager for [redin](https://github.com/sstoehrm/redin) — a re-frame inspired desktop UI framework.

## Install

```bash
curl -sL https://raw.githubusercontent.com/sstoehrm/redin-cli/main/install.sh | bash
```

Requires [Babashka](https://babashka.org/).

## Usage

### Create a new project

```bash
redin-cli new my-app
cd my-app
./redinw --dev main
```

This creates a project with:
- `.redin/` — pinned redin binary and runtime (gitignored)
- `redinw` — wrapper script (committed to git)
- `main.fnl` — starter counter app
- `theme.fnl` — Nord theme

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
