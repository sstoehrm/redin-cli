# redin-cli Revamp

Overhaul the CLI to support Fennel, Lua, and native Odin workflows with correct templates.

## Commands

| Command | Description |
|---|---|
| `redin-cli new-fnl <name>` | Scaffold a Fennel project |
| `redin-cli new-lua <name>` | Scaffold a Lua project |
| `redin-cli upgrade-to-native` | Add Odin source and native/ build entry point to existing project |
| `redin-cli update [version]` | Update redin in `.redin/` |
| `redin-cli latest` | Print latest version |

The old `new` command is removed.

## new-fnl

```
my-app/
  .redin/           # binary + runtime (gitignored)
  .gitignore
  redinw            # exec .redin/redin "$@"
  flsproject.fnl    # FLS extra-globals for redin
  main.fnl          # counter app with canvas background
```

### main.fnl

```fennel
(local dataflow (require :dataflow))
(local theme-mod (require :theme))
(local canvas (require :canvas))

(theme-mod.set-theme
  {:surface {:bg [46 52 64] :padding [24 24 24 24]}
   :heading {:font-size 48 :color [236 239 244] :weight 1}
   :button  {:bg [76 86 106] :color [236 239 244]
             :radius 6 :padding [8 16 8 16]}
   :button#hover {:bg [94 105 126]}})

(dataflow.init {:counter 0})
(global redin_get_state (. dataflow :_get-raw-db))

(reg-handler :event/inc
  (fn [db event] (update db :counter #(+ $1 1))))

(reg-sub :sub/counter
  (fn [db] (get db :counter)))

(canvas.register :background
  (fn [ctx]
    (let [t (redin.now) w ctx.width h ctx.height]
      (ctx.rect 0 0 w h {:fill [36 42 54]})
      (for [i 1 5]
        (let [x (+ (* w 0.5) (* (* w 0.3) (math.sin (+ (* t 0.2 i) (* i 1.5)))))
              y (+ (* h 0.5) (* (* h 0.3) (math.cos (+ (* t 0.15 i) (* i 2.0)))))]
          (ctx.circle x y (+ 30 (* 20 i)) {:fill [60 70 90 20]}))))))

(global main_view
  (fn []
    (let [count (subscribe :sub/counter)]
      [:stack {:viewport [[:top_left 0 0 :full :full]
                          [:top_left 0 0 :full :full]]}
        [:canvas {:provider :background :width :full :height :full}]
        [:vbox {:aspect :surface :layout :center}
          [:text {:aspect :heading :layout :center} (tostring count)]
          [:button {:aspect :button :click [:event/inc]
                    :width 120 :height 42}
                   "+1"]]])))
```

### flsproject.fnl

```fennel
{:lua-version "lua5.1"
 :extra-globals "get get-in assoc assoc-in update update-in dissoc dissoc-in reg-handler reg-sub subscribe dispatch reg-fx main_view redin_get_state redin"}
```

## new-lua

```
my-app/
  .redin/           # binary + runtime (gitignored)
  .gitignore
  redinw            # exec .redin/redin "$@"
  .luarc.json       # lua-language-server globals config
  main.lua          # counter app with canvas background
```

### main.lua

```lua
local dataflow = require("dataflow")
local theme = require("theme")
local canvas = require("canvas")

theme["set-theme"]({
  surface = {bg = {46, 52, 64}, padding = {24, 24, 24, 24}},
  heading = {["font-size"] = 48, color = {236, 239, 244}, weight = 1},
  button = {bg = {76, 86, 106}, color = {236, 239, 244},
            radius = 6, padding = {8, 16, 8, 16}},
  ["button#hover"] = {bg = {94, 105, 126}},
})

dataflow.init({counter = 0})
redin_get_state = dataflow["_get-raw-db"]

reg_handler("event/inc", function(db, event)
  return update(db, "counter", function(n) return (n or 0) + 1 end)
end)

reg_sub("sub/counter", function(db)
  return get(db, "counter")
end)

canvas.register("background", function(ctx)
  local t = redin.now()
  local w, h = ctx.width, ctx.height
  ctx.rect(0, 0, w, h, {fill = {36, 42, 54}})
  for i = 1, 5 do
    local x = w*0.5 + w*0.3 * math.sin(t*0.2*i + i*1.5)
    local y = h*0.5 + h*0.3 * math.cos(t*0.15*i + i*2.0)
    ctx.circle(x, y, 30 + 20*i, {fill = {60, 70, 90, 20}})
  end
end)

function main_view()
  local count = subscribe("sub/counter")
  return {"vbox", {},
    {"stack", {viewport = {
      {"top_left", 0, 0, "full", "full"},
      {"top_left", 0, 0, "full", "full"},
    }},
      {"canvas", {provider = "background", width = "full", height = "full"}},
      {"vbox", {aspect = "surface", layout = "center"},
        {"text", {aspect = "heading", layout = "center"}, tostring(count)},
        {"button", {aspect = "button", click = {"event/inc"},
                    width = 120, height = 42}, "+1"}}}}
end
```

### .luarc.json

```json
{
  "diagnostics.globals": [
    "redin", "redin_get_state",
    "get", "get_in", "assoc", "assoc_in",
    "update", "update_in", "dissoc", "dissoc_in",
    "reg_handler", "reg_sub", "subscribe", "dispatch", "reg_fx",
    "main_view"
  ]
}
```

## upgrade-to-native

Run from an existing project root (must have `.redin/`). Downloads the redin source into `.redin/` and copies the full host source into `native/` so the user owns the build.

The Odin host has package-internal symbols (`render_tree`, `node_rects`, `apply_scroll_events`) that can't be imported from outside the package. Rather than fighting the package boundary, `upgrade-to-native` copies the host source into `native/` where the user can modify it directly. The `providers.odin` file is added alongside the framework code.

### After upgrade

```
my-app/
  .redin/
    redin             # pre-built binary (still works as fallback)
    src/host/         # Odin source (reference copy)
    src/runtime/      # Fennel runtime
    vendor/           # fennel, luajit
    version
  native/             # user-owned copy of src/host/ + providers
    main.odin         # copied from .redin/src/host/main.odin, init_providers() injected
    render.odin       # copied from .redin/src/host/main.odin
    bridge/           # copied from .redin/src/host/bridge/
    canvas/           # copied from .redin/src/host/canvas/
    font/             # copied from .redin/src/host/font/
    input/            # copied from .redin/src/host/input/
    parser/           # copied from .redin/src/host/parser/
    text/             # copied from .redin/src/host/text/
    types/            # copied from .redin/src/host/types/
    providers.odin    # NEW: example canvas provider (user's code)
    build.sh          # odin build native/ -out:build/redin
  build/              # gitignored, native build output
  .gitignore          # updated to also ignore build/
  redinw              # updated to prefer build/redin over .redin/redin
  main.fnl or main.lua  # existing app code (unchanged)
```

### native/main.odin

A copy of `.redin/src/host/main.odin` with one line injected after `bridge.load_app`:

```odin
	// Register custom canvas providers
	init_providers()
```

The user owns this file and can modify the main loop freely.

### native/providers.odin

Example canvas provider template:

```odin
package host

import "canvas"
import rl "vendor:raylib"

// Example: register a native Odin canvas provider.
// Reference it from Fennel/Lua with [:canvas {:provider :my-provider ...}]

my_provider := canvas.Canvas_Provider{
	update = proc(rect: rl.Rectangle) {
		rl.DrawRectangleRec(rect, rl.Color{40, 40, 60, 255})
	},
}

init_providers :: proc() {
	canvas.register("my-provider", my_provider)
}
```

Note: the package is `host` (same as `main.odin`) since it lives in the same directory.

### native/build.sh

```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
mkdir -p "$PROJECT_DIR/build"
odin build "$SCRIPT_DIR" -out:"$PROJECT_DIR/build/redin"
```

### Updating native source

To update the framework source after a redin update, re-run `upgrade-to-native`. It re-copies the host source from `.redin/src/host/` into `native/`, preserving `providers.odin` and any other user-created `.odin` files (files not present in the framework source).

### redinw update

After upgrade, `redinw` prefers the native build:

```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/build/redin" ]; then
  exec "$SCRIPT_DIR/build/redin" "$@"
else
  exec "$SCRIPT_DIR/.redin/redin" "$@"
fi
```

### .gitignore update

Appends `build/` to `.gitignore`.

## Shared

### redinw (scripting-only, before upgrade)

```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$SCRIPT_DIR/.redin/redin" "$@"
```

### .gitignore (scripting-only)

```
.redin/
```

## What changes in redin-cli

Single file: `redin-cli` (Babashka script). Changes:
- Remove `cmd-new`, add `cmd-new-fnl` and `cmd-new-lua`
- Replace all template strings with correct API
- Add `cmd-upgrade-to-native`
- Add source download logic for upgrade (clone or tarball of redin source)
- Update the CLI help text

## What does NOT change

- `install.sh` — unchanged
- `update` command — unchanged (still downloads binary release into `.redin/`)
- `latest` command — unchanged
- GitHub release structure — unchanged
