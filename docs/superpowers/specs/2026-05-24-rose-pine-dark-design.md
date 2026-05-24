# Rose Pine dark theme + day/night auto-switch (native Plasma 6.5+)

Date: 2026-05-24
Status: design approved, pending writing-plans

## History

A previous draft of this spec (commit `fb93c08`, same filename) was built around
`darkman` as the scheduling daemon. That design was sound for Plasma 6.4 but
predated the verification of two facts:

- Plasma 6.5 (released 2025-10-21) shipped **native** automatic Global Theme
  switching via `knighttime` / `plasma-knighttimed`, driven by `geoclue2`.
- `xdg-desktop-portal-kde` already reports the freedesktop
  `color-scheme` preference based on the active Plasma color scheme.
- Ghostty implements CSI 2031, and Neovim 0.10+ natively reacts to it via
  `OptionSet background`.

Together those make `darkman` redundant on the rice's current stack
(Plasma 6.6.5, Ghostty, nvim 0.12.2). This rewrite picks the native path.

## Goal

Add a Rose Pine main (dark) variant alongside the existing Rose Pine Dawn rice
and have the system auto-switch at sunrise/sunset, covering the Plasma color
scheme, icon theme, wallpaper, Ghostty, and Neovim — using KDE's built-in
day/night cycle, with no third-party scheduler, no custom hooks, no cache
files.

## Decisions

- **Two Plasma Global Themes**, packaged as proper KDE Look-and-Feel bundles:
  `org.dertechie.rose-pine-dawn` and `org.dertechie.rose-pine-main`. Each
  bundles its own color scheme, icon-theme reference, wallpaper, and
  `defaults` mapping. Stock Breeze for Plasma Style and KWin decoration.
- **Theme packages live in a top-level `themes/` directory** in this repo
  (not `dot_local/`, not bundled in konsave). Each theme directory is
  self-contained with `LICENSE` and `README.md`, structured for publication
  to the KDE Store later via tar.gz upload. No separate repo for now.
- **Scheduling is Plasma-native:** `plasma-knighttimed` + `geoclue2`,
  controlled by four keys in `kdeglobals [KDE]`. No coordinates committed to
  the repo (geolocation comes from system Location Services).
- **Ghostty already wired correctly:** the existing
  `theme = light:Rose Pine Dawn,dark:Rose Pine Moon` line in
  `dot_config/ghostty/config.ghostty` becomes
  `theme = light:Rose Pine Dawn,dark:Rose Pine` (palette name swap) and
  starts working automatically once Plasma drives the portal preference.
- **Neovim:** CSI 2031 + `OptionSet background` autocmd. No plugin, no DBus
  listener, no fs-watcher, no cache file. Two small Lua edits.
- **No `darkman`.** Not in `packages/aur.txt`, not in `install.sh`.
- **No custom Plasma Style or KWin decoration.** Stock Breeze for both.
- **Color schemes derived from [rose-pine/palette](https://github.com/rose-pine/palette)**
  (MIT). Authored fresh, not vendored from `kelpwave/Rose-pine-for-KDE`
  (which lacks a LICENSE file and is Moon-only anyway).

## Architecture

```
geoclue2                                  System Settings → Colors and Themes
   │                                                │
   ▼                                                │  user picks day theme + night theme
plasma-knighttimed.service ◀─────────────  configuration (kdeglobals [KDE])
   │  sunrise/sunset transitions
   │
   ▼
KDE auto-switcher ──▶ plasma-apply-lookandfeel <day|night>
                            │
                            │  applies the bundled Global Theme:
                            │     • color scheme
                            │     • icon theme
                            │     • plasma style (stays stock)
                            │     • wallpaper
                            ▼
                xdg-desktop-portal-kde recomputes org.freedesktop.appearance.color-scheme
                            │
              ┌─────────────┼──────────────┐
              ▼             ▼              ▼
        Ghostty (auto)   GTK apps      Electron apps
              │ via existing config line
              │
              ▼
        Ghostty emits CSI 2031 to its child PTY
              │
              ▼
        Neovim flips `vim.o.background`
              │  OptionSet autocmd
              ▼
        :colorscheme rose-pine-dawn  /  :colorscheme rose-pine
```

**Daemons doing real work:** `geoclue2` (sunrise/sunset times from location)
and `plasma-knighttimed` (transition orchestrator). Both ship with the base
Plasma 6 install. Nothing else we add is a daemon.

## Files

### New, top-level `themes/`

```
themes/
├── README.md                          # what these are, install, publish, prior-art note
├── rose-pine-dawn/                    # publishable Global Theme package
│   ├── LICENSE                        # MIT
│   ├── metadata.json                  # KPackage metadata (Plasma 6 JSON format)
│   └── contents/
│       ├── defaults                   # INI mapping: ColorScheme, Icons.Theme, Wallpaper
│       ├── previews/preview.png       # 480×270 screenshot for System Settings picker
│       ├── colors/
│       │   └── RosePineDawnCustom.colors
│       └── wallpapers/
│           └── rose-pine-dawn/
│               ├── metadata.json
│               └── contents/
│                   ├── screenshot.png
│                   └── images/3840x2160.png
└── rose-pine-main/                    # symmetric; ColorScheme=RosePineCustom,
    └── ...                              # Icons.Theme=Papirus-Dark, etc.
```

### `metadata.json` shape (Dawn; Main is symmetric)

```json
{
  "KPackageStructure": "Plasma/LookAndFeel",
  "KPlugin": {
    "Id": "org.dertechie.rose-pine-dawn",
    "Name": "Rosé Pine Dawn",
    "Description": "Soho-vibe light theme based on the Rosé Pine Dawn palette",
    "Authors": [{ "Name": "Mike Esser", "Email": "info@dertechie.de" }],
    "Category": "Plasma Look and Feel",
    "License": "MIT",
    "Version": "1.0",
    "Website": "https://github.com/DerTechie/dotfiles/tree/main/themes"
  }
}
```

### `defaults` file (Dawn)

INI-formatted; `[section][group]` headers point to Plasma config file + group.

```ini
[kdeglobals][KDE]
LookAndFeelPackage=org.dertechie.rose-pine-dawn

[kdeglobals][General]
ColorScheme=RosePineDawnCustom

[kdeglobals][Icons]
Theme=Papirus-Light

[plasmarc][Theme]
name=default

[kwinrc][org.kde.kdecoration2]
library=org.kde.breeze
theme=Breeze

[Wallpaper]
Image=rose-pine-dawn
```

Main differs in: `Id` slug, `ColorScheme=RosePineCustom`,
`Icons.Theme=Papirus-Dark`, `Wallpaper=rose-pine-main`.

### Repo files that change

| Path | Change |
|---|---|
| `install.sh` | Install both Look-and-Feel packages via `kpackagetool6`; wire up auto-switch via `kwriteconfig6`; drop the `plasma-apply-colorscheme RosePineDawnCustom` line. |
| `packages/pacman.txt` | No additions. `knighttime`, `geoclue`, `kpackagetool6` already pulled in by `plasma-meta`. |
| `packages/aur.txt` | **No additions.** No `darkman`. |
| `dot_config/ghostty/config.ghostty` | `dark:Rose Pine Moon` → `dark:Rose Pine`. |
| `dot_config/nvim/lua/plugins/colorscheme.lua` | Replace static `colorscheme = "rose-pine-dawn"` with a function reading `vim.o.background`. |
| `dot_config/nvim/lua/config/autocmds.lua` | Append one `OptionSet background` autocmd that calls `:colorscheme`. |
| `konsave/rose-pine-dawn.knsv` | Re-export. Strips bundled `~/.local/share/color-schemes/*` and `~/.local/share/wallpapers/*` (those moved into the theme packages). Keeps panel/widget/dolphin state and the new `kdeglobals [KDE]` keys. |
| `CLAUDE.md` | Document the `themes/` directory and its publish-readiness rationale; update the konsave section to reflect its reduced scope; keep the named-color-scheme pitfall. |
| `README.md` | Stack section: dual Rose Pine Global Themes + KDE-native day/night auto-switch. |

## Plasma configuration

Verified against `kcms/lookandfeel/lookandfeelsettings.kcfg` in
plasma-workspace master. All keys live in `~/.config/kdeglobals` group `[KDE]`.

| Key | Value | Default | Notes |
|---|---|---|---|
| `AutomaticLookAndFeel` | `true` | `false` | Master switch. |
| `DefaultLightLookAndFeel` | `org.dertechie.rose-pine-dawn` | `org.kde.breeze.desktop` | Day theme. |
| `DefaultDarkLookAndFeel` | `org.dertechie.rose-pine-main` | `org.kde.breezedark.desktop` | Night theme. |
| `AutomaticLookAndFeelOnIdle` | (default `true`) | `true` | Only flip when user has been idle ≥ N seconds. |
| `AutomaticLookAndFeelIdleInterval` | (default `5`) | `5` | Friendly to mid-task transitions. |

**Precondition — location:** `plasma-knighttimed` reads location via KDE's
geolocation (which delegates to `geoclue2`). The user must have **Location
Services enabled** in System Settings → Privacy → Location for sunrise/sunset
to be computed. `install.sh` does not enable Location Services automatically —
that would surprise visitors who fork the repo on a private machine.
`README.md` documents the precondition.

## `install.sh` additions

After the existing chezmoi + papirus-folders + konsave blocks:

```bash
echo "==> Installing Rosé Pine Global Themes"
for theme in rose-pine-dawn rose-pine-main; do
  if kpackagetool6 --type Plasma/LookAndFeel --list 2>/dev/null \
        | grep -q "^org.dertechie.$theme$"; then
    kpackagetool6 --type Plasma/LookAndFeel --upgrade "$REPO_DIR/themes/$theme"
  else
    kpackagetool6 --type Plasma/LookAndFeel --install "$REPO_DIR/themes/$theme"
  fi
done

echo "==> Enabling automatic day/night Global Theme switching"
kwriteconfig6 --file kdeglobals --group KDE \
  --key AutomaticLookAndFeel true
kwriteconfig6 --file kdeglobals --group KDE \
  --key DefaultLightLookAndFeel org.dertechie.rose-pine-dawn
kwriteconfig6 --file kdeglobals --group KDE \
  --key DefaultDarkLookAndFeel org.dertechie.rose-pine-main

echo "==> Seeding initial Global Theme"
plasma-apply-lookandfeel --apply org.dertechie.rose-pine-dawn || true
```

And **remove** the existing line:

```bash
# REMOVED:
# plasma-apply-colorscheme RosePineDawnCustom || true
```

**Idempotency:** `kpackagetool6 --upgrade` updates an existing package without
error; the if/else handles the first-install case. `kwriteconfig6` overwrites
to the desired values on every run. `plasma-apply-lookandfeel` on an already-
active theme is a no-op visually. Re-running `install.sh` on a configured
system is safe.

## Neovim integration

### `dot_config/nvim/lua/plugins/colorscheme.lua` (replaces current content)

```lua
local function variant()
  return vim.o.background == "dark" and "rose-pine" or "rose-pine-dawn"
end

return {
  { "rose-pine/neovim", name = "rose-pine" },

  {
    "LazyVim/LazyVim",
    opts = { colorscheme = variant() },
  },
}
```

### `dot_config/nvim/lua/config/autocmds.lua` (appended to existing file)

```lua
vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "background",
  callback = function()
    local scheme = vim.v.option_new == "dark" and "rose-pine" or "rose-pine-dawn"
    pcall(vim.cmd.colorscheme, scheme)
  end,
})
```

### Rose Pine plugin variant naming

| Plugin variant | Background | Use |
|---|---|---|
| `rose-pine-dawn` | light | day |
| `rose-pine` | dark | night (our pick) |
| `rose-pine-moon` | dark, more muted | not used |

Matches Ghostty's bundled theme names (`Rose Pine Dawn`, `Rose Pine`,
`Rose Pine Moon`).

### Graceful degradation

| Environment | Behavior |
|---|---|
| nvim inside Ghostty | Auto-flips. |
| nvim inside a TTY | Stuck on light. Acceptable — TTY has no portal. |
| nvim inside a non-2031 terminal | Stuck on whatever the terminal reports. Acceptable — the rice only uses Ghostty. |
| nvim inside tmux | Currently broken (tmux/tmux#4286 — tmux doesn't pass CSI 2031). Documented as a known gap. If tmux becomes part of the rice, switch to `auto-dark-mode.nvim` as the fallback. |

## Konsave's reduced scope

The `.knsv` snapshot previously bundled theme assets (`~/.local/share/color-schemes/`,
`~/.local/share/wallpapers/`, etc.). With Global Theme packaging, those move
into `themes/`. Konsave now owns:

- Panel layouts, widget configs, dolphin/kate/etc application state.
- The `kdeglobals [KDE]` keys driving auto-switch (so a fresh install lands
  with auto-switch already configured).

It no longer owns: `~/.local/share/color-schemes/*`,
`~/.local/share/wallpapers/*`, `~/.local/share/plasma/look-and-feel/*`.
The `.knsv` shrinks. `CLAUDE.md`'s "Updating the Konsave snapshot" section
needs corresponding edits — defer specifics to the implementation plan.

## Out of scope

- **`darkman`** — replaced by Plasma 6.5+ native.
- **Custom hook scripts, state files, cache files** — KDE owns orchestration.
- **Custom Plasma Style** — stock Breeze is color-scheme-aware.
- **Custom KWin decoration** — stock Breeze decoration is color-scheme-aware.
- **Cursor theme swap** — `rose-pine-cursor` has no dark variant.
- **Splash screen** — cosmetic, low ROI.
- **Tmux** — not currently part of the rice; CSI 2031 doesn't traverse tmux yet.
- **Konsole color sync** — rice uses Ghostty, not Konsole.
- **Obsidian** — manual post-install step, unchanged.
- **Publishing to KDE Store** — `themes/` is structured for it; actual upload is a later task.

## Open questions (for writing-plans / implementation)

1. **Exact wallpaper file** for Rose Pine main (and Dawn — current Dawn rice
   may be using something we should snapshot or replace).
2. **Color scheme mapping** — palette role → KDE color role decisions
   (e.g. `BackgroundNormal` ← `base` vs `surface`).
3. **`kpackagetool6 --upgrade` semantics** on a never-installed package —
   the sketched if/else covers both cases but verify in fresh-install test.
4. **`plasma-apply-lookandfeel --apply` vs knighttimed override.** Does the
   seeding call get respected, or will knighttimed flip it back immediately?
   If knighttimed handles seeding itself once `AutomaticLookAndFeel=true`,
   the manual seeding line is dead weight.
5. **Konsave re-export workflow** changes — exact CLAUDE.md edits.

## Success criteria

1. Fresh Arch install: `bash install.sh` lands in the correct day/night
   theme for the current time of day, with all surfaces (Plasma color
   scheme, icons, wallpaper, Ghostty, running Neovim) matching.
2. Manual toggle via System Settings → Quick Settings (or
   `plasma-apply-lookandfeel --apply org.dertechie.rose-pine-main`) flips
   every surface within a couple of seconds, gated by the 5s idle threshold.
3. Natural sunset transition flips everything correctly. The idle gate
   prevents mid-task surprises.
4. Re-running `bash install.sh` on a configured system is a no-op for
   theme state.
5. Each `themes/<name>/` directory is standalone-installable by an outsider:
   `git clone`, then `kpackagetool6 -t Plasma/LookAndFeel -i themes/rose-pine-dawn`.
6. Both `.colors` files preview correctly in System Settings → Colors.
7. No `darkman` references remain in `packages/aur.txt`, `install.sh`, or
   anywhere else in the repo.
