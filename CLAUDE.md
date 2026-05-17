# CLAUDE.md

Guidance for Claude Code when working in this repo.

## What this repo is

Personal dotfiles for bootstrapping a fresh Arch Linux + KDE Plasma 6 install on the owner's machine. It is public so others can copy whatever pieces they find useful (themes, package lists, ghostty config), but it is **not** a generic framework — assume the owner is the only "user" and that defaults are tailored to their hardware (AMD GPU, amd-ucode) and preferences (Rosé Pine Dawn/Moon, JetBrains Mono Nerd Font).

`install.sh` is the entry point on a fresh system; everything else exists to support it.

## Repo layout

```
install.sh              # One-shot bootstrap: yay → pacman → AUR → chezmoi → konsave
packages/
  pacman.txt            # Official-repo packages, one per line
  aur.txt               # AUR packages, one per line
dot_bashrc              # chezmoi source for ~/.bashrc
dot_config/             # chezmoi source for ~/.config/...
dot_local/              # chezmoi source for ~/.local/...
konsave/
  rose-pine-dawn.knsv   # Plasma state snapshot, applied at end of install
.chezmoiignore          # Files in this repo that chezmoi should NOT apply to $HOME
```

## chezmoi naming

This repo is managed with [chezmoi](https://www.chezmoi.io/). File and directory names follow chezmoi's source-name conventions:

- `dot_foo` → `~/.foo` (e.g. `dot_bashrc` → `~/.bashrc`, `dot_config/ghostty/` → `~/.config/ghostty/`)
- Anything that should live in the repo but **not** be applied to `$HOME` must be listed in `.chezmoiignore` (currently: `README.md`, `LICENSE`, `.gitignore`, `install.sh`, `packages`, `konsave`).

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

### Updating the Konsave snapshot

`konsave/rose-pine-dawn.knsv` is a binary snapshot of the Plasma configuration. After making Plasma changes that should be part of the rice:

```bash
konsave -s rose-pine-dawn         # save current state into the named profile
konsave -e rose-pine-dawn         # export to .knsv in the cwd
mv rose-pine-dawn.knsv konsave/
```

Commit the regenerated `.knsv`. Note this file is ~9 MB — expect noisy diffs.

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
