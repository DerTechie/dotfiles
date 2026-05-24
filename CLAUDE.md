# CLAUDE.md

Guidance for Claude Code when working in this repo.

## What this repo is

Personal dotfiles for bootstrapping a fresh Arch Linux + KDE Plasma 6 install on the owner's machine. It is public so others can copy whatever pieces they find useful (themes, package lists, ghostty config), but it is **not** a generic framework — assume the owner is the only "user" and that defaults are tailored to their hardware (AMD GPU, amd-ucode) and preferences (Rosé Pine Dawn/Main, JetBrains Mono Nerd Font).

`install.sh` is the entry point on a fresh system; everything else exists to support it.

## Repo layout

```
install.sh              # One-shot bootstrap: yay → pacman → AUR → services → chezmoi → konsave → themes
packages/
  pacman.txt            # Official-repo packages, one per line
  aur.txt               # AUR packages, one per line
dot_bashrc              # chezmoi source for ~/.bashrc
dot_config/             # chezmoi source for ~/.config/...
themes/                 # Publishable KDE Look-and-Feel packages (rose-pine-dawn, rose-pine-main)
konsave/
  rose-pine-dawn.knsv   # Plasma state snapshot (panel/widget/dolphin state + kdeglobals [KDE] keys)
.chezmoiignore          # Files in this repo that chezmoi should NOT apply to $HOME
```

Plasma Global Themes live in [`themes/`](themes/) as proper KDE Look-and-Feel packages and are installed by `install.sh` via `kpackagetool6`. The konsave `.knsv` no longer bundles `~/.local/share/{color-schemes,wallpapers,plasma/look-and-feel}` — it now carries only panel/widget/dolphin/etc. application state plus the `kdeglobals [KDE]` keys that drive day/night auto-switching. If you ever add per-user assets that neither `themes/` nor konsave captures, put them under `dot_local/` and chezmoi will manage them.

## chezmoi naming

This repo is managed with [chezmoi](https://www.chezmoi.io/). File and directory names follow chezmoi's source-name conventions:

- `dot_foo` → `~/.foo` (e.g. `dot_bashrc` → `~/.bashrc`, `dot_config/ghostty/` → `~/.config/ghostty/`)
- Anything that should live in the repo but **not** be applied to `$HOME` must be listed in `.chezmoiignore` (currently: `README.md`, `LICENSE`, `.gitignore`, `install.sh`, `packages`, `konsave`, `themes`, `docs`).

When adding a new dotfile, name the source path with the `dot_` prefix on every leading-dot component, and verify it isn't accidentally excluded by `.chezmoiignore`.

## Common tasks

### Adding a package

- Official repo → append the package name to `packages/pacman.txt`.
- AUR → append to `packages/aur.txt`.
- One package per line. Keep the list sorted alphabetically (current convention — preserve it when adding entries).
- Don't reorder existing entries unless asked; keep diffs minimal.

### Adding a new dotfile

1. Place the file under the repo root using chezmoi's `dot_` naming (see above).
2. If it depends on a package, make sure that package is in `packages/pacman.txt` or `packages/aur.txt`.
3. The next `install.sh` run (or `chezmoi apply`) will deploy it.

### Updating a theme bundle

The two Plasma Global Themes live in `themes/rose-pine-dawn/` and
`themes/rose-pine-main/`. Each is a complete KPackage tree with
`metadata.json`, `contents/defaults`, color scheme, wallpaper, and preview.

To iterate on a theme:

1. Edit the relevant files under `themes/<bundle>/`.
2. Re-install into the live session:

```bash
kpackagetool6 --type Plasma/LookAndFeel --upgrade themes/rose-pine-dawn   # or rose-pine-main
plasma-apply-lookandfeel --apply org.dertechie.rose-pine-dawn             # or rose-pine-main
```

3. To publish a release tarball later:

```bash
tar -czf rose-pine-dawn.tar.gz -C themes rose-pine-dawn
```

`install.sh` is idempotent: re-running it calls `kpackagetool6 --upgrade`
on already-installed packages, so the next bootstrap picks up edits.

### Updating the Konsave snapshot

`konsave/rose-pine-dawn.knsv` is a binary snapshot of the Plasma configuration.
Since the day/night auto-switch landed, its scope is narrower: panel/widget
layout, dolphin/kate/etc. application state, and the `kdeglobals [KDE]`
auto-switch keys. It no longer bundles color schemes, wallpapers, or
look-and-feel packages — those live in `themes/` as proper KPackage bundles.

A konsave-config gotcha: konsave 2.3.0 can't handle slashed sub-entries
(e.g. `plasma/look-and-feel`). The user-level `~/.config/konsave/conf.yaml`
splits the prior `plasma` entry into a separate `plasma_assets` export
group with `location: $SHARE_DIR/plasma` and `entries: [desktoptheme,
plasmoids, containmentpreviews]` so non-theme plasma subdirs still ride
along.

After making Plasma changes that should be part of the rice:

```bash
konsave -s rose-pine-dawn -f      # overwrite the named profile with current state
konsave -e rose-pine-dawn \
  -d "$REPO_DIR/konsave" \
  -n rose-pine-dawn               # export to <repo>/konsave/rose-pine-dawn.knsv
```

konsave appends a timestamp to the filename despite `-n`; rename back to
`rose-pine-dawn.knsv` before committing. The file is now smaller than the
pre-themes/ era (~1 MB vs. ~9 MB) — expect diffs proportional to what
actually changed.

**Pitfall — color scheme must be a *named* scheme.** Plasma 6's first-session
logic can reset `kdeglobals` if the active color scheme is identified only by
`ColorSchemeHash` and not `ColorScheme=NAME`. To ensure the snapshot survives
a fresh install:

1. System Settings → Colors → "Save current colors as new scheme…" → give it
   a name (e.g. `RosePineDawnCustom` or `RosePineCustom`).
2. Apply it (or run `plasma-apply-lookandfeel --apply org.dertechie.rose-pine-dawn`)
   so `kdeglobals [General]` gains a `ColorScheme=` line that names the scheme.
3. Then re-export the konsave snapshot.

`install.sh` seeds the live session via
`plasma-apply-lookandfeel -k --apply org.dertechie.rose-pine-dawn`, then
chains `plasma-apply-colorscheme RosePineDawnCustom` and
`plasma-apply-wallpaperimage <bundle>/contents/wallpapers/.../3840x2160.png`
before writing the auto-switch keys via `kwriteconfig6`. All three calls
are needed because:

- `plasma-apply-lookandfeel` writes `[General] ColorScheme=NAME` and
  (sometimes) the wallpaper, but it does **not** propagate the color
  scheme's `[WM]` section into `kdeglobals`. Without `plasma-apply-colorscheme`,
  titlebars keep the previous WM colors (e.g. Breeze gray) over Rose
  Pine widget colors, producing the "window titles look off" symptom.
- `plasma-apply-lookandfeel` honors user-pinned wallpapers (won't
  override an absolute path the user previously set), so wallpaper has
  to be applied explicitly.
- The `-k/--keep-auto` flag prevents `plasma-apply-lookandfeel` from
  stripping `AutomaticLookAndFeel`. Without it, manual reapplies (CLI
  or System Settings → Global Themes) silently disable the day/night
  switch.

### `rose-pine` helper

`dot_local/bin/executable_rose-pine` (chezmoi-deployed to
`~/.local/bin/rose-pine`) is a thin wrapper that does the full triple
apply (`-k --apply` → `plasma-apply-colorscheme` → `plasma-apply-wallpaperimage`)
for `dawn` or `main`, and `rose-pine auto` re-enables `AutomaticLookAndFeel`.

It bounces through the *other* variant's color scheme before applying
the target — `plasma-apply-colorscheme` short-circuits with "already set"
when `[General] ColorScheme=` already names the target (which it does
after `plasma-apply-lookandfeel`), and short-circuiting skips the `[WM]`
rewrite. The bounce forces the rewrite.

### `plasma-knighttimed` location (`knighttimerc`)

The day/night switch needs a location to compute sunrise/sunset.
Config file is `~/.config/knighttimerc`:

```ini
[Location]
Automatic=false
Latitude=52.52
Longitude=13.40
```

`install.sh` seeds these keys (Berlin default) only when the file is
missing, so re-running the script never clobbers a user-set location.
Override via System Settings → Day-Night Cycle for precise local coords.

**Do not rely on `Automatic=true`.** On vanilla Arch + KDE it gives a
(0, 0) equator schedule (`noon` at local 12:00, transitions at exactly
±6h) because:

1. KDE ships no geoclue agent, so headless apps need an allowlist entry
   in `/etc/geoclue/conf.d/<name>.conf` (e.g. `[org.kde.knighttimed]
   allowed=true system=true`).
2. Even with permission, geoclue's default `[ip]` backend method is
   `ichnaea` — that's the Mozilla Location Service URL, which Mozilla
   shut down in 2024. All `[ip]` requests return HTTP 404.
3. The `[wifi]` backend defaults to `api.beacondb.net` (alive) but
   needs WiFi hardware + nearby APs in BeaconDB.

A working Automatic setup needs *both* the agent drop-in *and* an `[ip]`
method override (e.g. `method=reallyfreegeoip` for IP-only desktops).
Not worth the moving parts for a single-user rice — Manual is fine.

### Testing changes to `install.sh`

`install.sh` is destructive enough (sudo, pacman, sed on `/etc/pacman.conf`) that it should not be edited blindly. Before pushing changes:

- Dry-run intent: read the script end-to-end and confirm idempotency for the section being changed.
- Prefer testing on a fresh Arch VM (e.g. via the `virt-manager` setup this repo already installs) rather than on the live system.
- Re-running the script on an already-set-up system should be safe (it uses `--needed --noconfirm` and guards for yay/multilib) — preserve that property.

## Constraints

- **Arch-only.** `install.sh` exits early on non-Arch systems via `/etc/arch-release`. Don't add cross-distro abstractions.
- **Single user.** Don't add multi-user scaffolding, host-specific templating, or chezmoi `.tmpl` files unless explicitly requested.
- **Public but personal.** Don't strip identifying details (paths like `/home/dertechie/...` in `dot_bashrc`, AMD-specific packages) just because the repo is public — that's intentional. If a path needs to be portable, the owner will say so.
- **Don't invent contribution docs.** This isn't accepting PRs as a project; no `CONTRIBUTING.md`, no issue templates, no CI unless asked.

## Style

- Keep `install.sh` POSIX-ish bash with `set -euo pipefail` and clear `echo "==> ..."` step banners. Match the existing style.
- README and other docs are intentionally terse. Don't pad with marketing prose.
