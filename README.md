# dotfiles

![Desktop screenshot](assets/screenshot.png)

My Arch Linux + KDE Plasma 6 + Rosé Pine Dawn rice.

## Restore on a fresh Arch install

```bash
git clone https://github.com/DerTechie/dotfiles.git ~/Repositories/github.com/DerTechie/dotfiles
bash ~/Repositories/github.com/DerTechie/dotfiles/install.sh
```

Log out and back in (or reboot) after the script finishes so group memberships (`docker`, `libvirt`) and the Plasma session pick up all changes.

## Stack

- **Desktop:** KDE Plasma 6 with native day/night Global Theme auto-switch (Rosé Pine Dawn ↔ Rosé Pine, driven by `plasma-knighttimed` with a manual lat/lon — geoclue's Automatic mode is broken on vanilla Arch because Mozilla Location Service shut down in 2024 and there's no KDE geoclue agent)
- **Terminal:** Ghostty with Rosé Pine Dawn/Rosé Pine (follows the freedesktop appearance portal)
- **Editor:** Neovim with LazyVim, flipping rose-pine-dawn ↔ rose-pine via CSI 2031 / `OptionSet background`
- **Icons:** Papirus Light (day) / Papirus Dark (night) with palebrown folders
- **Fonts:** Inter (UI), JetBrains Mono Nerd Font (terminal, fixed-width)

## Fonts

- **Inter** for the system UI. KDE defaults to Noto Sans, which is designed as a universal-script fallback — optimized for glyph coverage across writing systems, not for screen-UI density. Inter is purpose-built for computer screens (tall x-height, open apertures, tabular numbers, hinted for small UI sizes) and is the de-facto modern UI font on the web and in GNOME (as the basis for Adwaita Sans).
- **JetBrains Mono Nerd Font** for monospace (Ghostty, Plasma's fixed-width slot, Neovim). Designed for code: increased letter height inside brackets/parens, distinguished similar glyphs (1/l/I, 0/O), and the Nerd Font variant bundles the icon glyphs that Ghostty, Lazygit, fastfetch, and Neovim plugins expect.

## Manual override

`rose-pine dawn|main|auto` (installed at `~/.local/bin/rose-pine`) flips the
Global Theme without going through System Settings. It applies the Look-and-Feel,
forces the color scheme's `[WM]` titlebar colors into `kdeglobals` (Plasma's
own L&F applier doesn't), and pins the bundle's wallpaper. `rose-pine auto`
re-enables the day/night auto-switch.

## Manual post-install steps

- **Adjust your Day-Night Cycle location** (optional) — `install.sh` seeds `~/.config/knighttimerc` with a Berlin default (52.52, 13.40). Override via System Settings → Day-Night Cycle → Location: Manual if you want precise local sunrise/sunset. KDE's "Automatic" option there is broken on Arch (see Stack note above) so leave it on Manual.
- **Obsidian** — settings (theme, plugins, hotkeys, appearance) are stored per-vault under `<vault>/.obsidian/` rather than globally, so they're not managed here. After opening a vault, install the Rosé Pine theme via Settings → Appearance → Themes → Manage → search "Rosé Pine".

## Credits

- [Rosé Pine](https://rosepinetheme.com/) palette and themes
- [rose-pine/wallpapers](https://github.com/rose-pine/wallpapers) for the 4K wallpapers bundled in `themes/`
- [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) icons
- [LazyVim](https://www.lazyvim.org/) Neovim distribution
- [Konsave](https://github.com/Prayag2/konsave) for Plasma state
- [chezmoi](https://www.chezmoi.io/) for dotfile management

## License

MIT — see [LICENSE](LICENSE).
