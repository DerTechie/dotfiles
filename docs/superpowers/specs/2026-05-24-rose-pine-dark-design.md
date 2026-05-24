# Rose Pine dark theme + day/night auto-switch

Date: 2026-05-24
Status: design approved, pending user review of spec → writing-plans

## Goal

Add a Rose Pine (main, dark) variant alongside the existing Rose Pine Dawn rice
and have the system auto-switch at sunrise/sunset, covering the Plasma color
scheme, icon theme, wallpaper, Ghostty, and Neovim — without requiring the user
to flip anything by hand.

## Decisions

- **Dark variant:** Rose Pine *main* (not Moon). Saved as a *named* Plasma color
  scheme `RosePineCustom` for the same reason the existing
  `RosePineDawnCustom` is named — Plasma 6's first-session logic can reset
  `kdeglobals` if the active scheme is identified only by `ColorSchemeHash`
  (see CLAUDE.md, "Updating the Konsave snapshot" pitfall).
- **Switching daemon:** `darkman` (AUR). Uses `usegeoclue: true` so no
  coordinates are checked into the public repo. `portal: true` makes Ghostty
  and GTK apps follow the system preference automatically. `dbusserver: true`
  exposes `darkman toggle` for manual override.
- **Asset delivery:** the new Plasma color scheme and wallpaper land in
  `~/.local/share/` and get baked into a re-exported `rose-pine-dawn.knsv`.
  Matches the convention in CLAUDE.md ("theme assets are bundled into the
  konsave `.knsv` via its `export:` section"); avoids splitting theme assets
  across konsave and chezmoi.
- **Neovim auto-flip:** libuv `vim.uv.new_fs_event()` watcher on
  `~/.cache/darkman-mode` in `lua/config/autocmds.lua`. The darkman hook only
  writes the file; running nvim instances pick it up on the next watcher tick.
  No external signaling, no socket discovery.

## Architecture

```
┌────────────┐   sunrise/sunset    ┌─────────────┐
│  geoclue2  │ ──────────────────▶ │   darkman   │ (systemd user unit)
└────────────┘                     └──────┬──────┘
                                          │ fires hooks + xdg-portal signal
                          ┌───────────────┼────────────────┐
                          ▼               ▼                ▼
              ~/.config/darkman/    ~/.config/darkman/   xdg-desktop-portal
              light-mode.d/*        dark-mode.d/*       (color-scheme: light|dark)
                          │               │                │
                          └───────┬───────┘                │
                                  ▼                        ▼
                  plasma-apply-colorscheme        Ghostty (auto, no extra code)
                  plasma-apply-wallpaperimage     GTK apps via portal
                  kwriteconfig6 (icon theme)
                  touch ~/.cache/darkman-mode      ← read by nvim fs-watcher
```

**Boundary contract:** darkman owns "what mode is it." Hook scripts own
"translate mode → desktop state." Each hook is a single bash file that can be
run directly for debugging.

## Files

### New, chezmoi-managed

| Path | Purpose |
|---|---|
| `dot_config/darkman/config.yaml` | `usegeoclue: true`, `portal: true`, `dbusserver: true` |
| `dot_config/darkman/light-mode.d/10-plasma.sh` | Apply Dawn scheme + wallpaper, Papirus-Light, write mode file |
| `dot_config/darkman/dark-mode.d/10-plasma.sh` | Apply Rose Pine main + wallpaper, Papirus-Dark, write mode file |
| `dot_config/nvim/lua/config/theme.lua` | Shared `variant()` helper used by both colorscheme.lua and autocmds.lua |

### New, live system → bundled into the konsave snapshot

| Path | Purpose |
|---|---|
| `~/.local/share/color-schemes/RosePineCustom.colors` | Rose Pine main palette as a named Plasma color scheme |
| `~/.local/share/wallpapers/RosePineMain/contents/images/...` | Rose Pine main wallpaper (picked from rosepinetheme.com; swappable later) |

### Modified

| Path | Change |
|---|---|
| `packages/aur.txt` | Add `darkman` (preserve alphabetical order) |
| `install.sh` | `systemctl --user enable --now darkman.service` + `darkman run --once` |
| `dot_config/ghostty/config.ghostty` | `dark:Rose Pine Moon` → `dark:Rose Pine` |
| `dot_config/nvim/lua/plugins/colorscheme.lua` | Replace static `colorscheme = "rose-pine-dawn"` with `colorscheme = require("config.theme").variant()` |
| `dot_config/nvim/lua/config/autocmds.lua` | Append fs-watcher block to existing file |
| `konsave/rose-pine-dawn.knsv` | Re-export so it carries the new `.colors` file + wallpaper |
| `README.md` | Stack section: dual theme + darkman note |
| `CLAUDE.md` | Extend the "named color scheme" pitfall to cover both schemes |

## Hook script contracts

Each hook script:

- Is a single bash file with `set -euo pipefail` and `echo "==> ..."` step
  banners, matching `install.sh` style.
- Is independently runnable for debugging: `bash ~/.config/darkman/dark-mode.d/10-plasma.sh`.
- Writes `dark` or `light` to `~/.cache/darkman-mode` as its last step.

### `dark-mode.d/10-plasma.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "==> Switching to Rose Pine (dark)"

plasma-apply-colorscheme RosePineCustom
plasma-apply-wallpaperimage \
  "$HOME/.local/share/wallpapers/RosePineMain/contents/images/3840x2160.png"

kwriteconfig6 --file kdeglobals --group Icons --key Theme Papirus-Dark
qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true

echo "dark" > "$HOME/.cache/darkman-mode"
```

### `light-mode.d/10-plasma.sh`

Symmetric: `RosePineDawnCustom`, dawn wallpaper path, `Papirus-Light`,
write `light`.

## Neovim integration

`lua/config/theme.lua`:

```lua
local M = {}
local mode_file = vim.fn.expand("~/.cache/darkman-mode")

function M.variant()
  local f = io.open(mode_file, "r")
  if not f then return "rose-pine-dawn" end
  local m = f:read("*l"); f:close()
  return m == "dark" and "rose-pine-main" or "rose-pine-dawn"
end

return M
```

`lua/config/autocmds.lua` (appended to existing file):

```lua
local theme = require("config.theme")

local apply = vim.schedule_wrap(function()
  pcall(vim.cmd.colorscheme, theme.variant())
end)

local w = vim.uv.new_fs_event()
if w then
  w:start(vim.fn.expand("~/.cache/darkman-mode"), {}, function() apply() end)
end
```

`lua/plugins/colorscheme.lua`:

```lua
return {
  { "rose-pine/neovim", name = "rose-pine" },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = require("config.theme").variant() },
  },
}
```

The fs-watcher fires on file change; `vim.schedule_wrap` lands the colorscheme
call on the main loop. Both running nvim and freshly-started nvim land on the
same variant.

## install.sh additions

After the existing "Enabling system services" block:

```bash
echo "==> Enabling darkman (user service)"
systemctl --user enable --now darkman.service
```

After the existing "Applying color scheme by name" block:

```bash
echo "==> Seeding initial light/dark mode"
darkman run --once || true
```

Both are idempotent on an already-set-up system. `|| true` on the seeding call
covers the first-boot edge case where geoclue hasn't reported a position yet —
the hook re-fires at the next sunrise/sunset regardless.

## Konsave update workflow (one-time, for this change)

Following the existing pitfall workflow in CLAUDE.md:

1. System Settings → Colors → "Save current colors as new scheme…" →
   `RosePineCustom` (with Rose Pine main palette loaded).
2. Drop the Rose Pine main wallpaper at
   `~/.local/share/wallpapers/RosePineMain/contents/images/...`.
3. Switch the live color scheme back to Dawn so the snapshot's active scheme
   stays light: `plasma-apply-colorscheme RosePineDawnCustom`.
4. `konsave -s rose-pine-dawn -f` (overwrite the named profile with current state).
5. `konsave -e rose-pine-dawn -d "$REPO_DIR/konsave" -n rose-pine-dawn`,
   rename off the timestamp suffix, commit.

## Out of scope

- KDE global theme / look-and-feel swap. The Dawn look-and-feel is already
  bundled; a separate Rose Pine main look-and-feel is not.
- GTK dark theme switching — handled automatically by
  `rose-pine-gtk-theme-full` + xdg-desktop-portal once darkman sets the
  preference.
- Cursor theme swap (`rose-pine-cursor` has no dark variant).
- Obsidian — still a manual post-install step per the README.
- Per-app retry if a hook step fails. Hooks log to journald via the
  `darkman.service` unit; debug by running the hook script directly.

## Success criteria

- `darkman toggle` flips Plasma color scheme, icon theme, wallpaper, and
  running Neovim sessions within ~1 second.
- On a fresh Arch install, `bash install.sh` lands in the correct day/night
  mode for the time of day.
- Ghostty respects the portal preference (existing `light:/dark:` config line
  starts working without further changes).
- Re-running `install.sh` on a configured system is safe and a no-op for
  darkman setup.
