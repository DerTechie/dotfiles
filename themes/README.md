# Rosé Pine Global Themes for KDE Plasma 6

Two Plasma Look-and-Feel packages — `org.dertechie.rose-pine-dawn` (light) and
`org.dertechie.rose-pine-main` (dark) — built from the
[Rosé Pine palette](https://github.com/rose-pine/palette). Each bundles its
own color scheme, icon-theme reference, 4K wallpaper, and `defaults` mapping.

These are structured for publication to the KDE Store but not yet uploaded.
The parent repo ([DerTechie/dotfiles](https://github.com/DerTechie/dotfiles))
installs them via `kpackagetool6` and wires them up for native automatic
day/night switching via Plasma 6.5+'s built-in `plasma-knighttimed`.

## Layout

```
rose-pine-dawn/
  LICENSE
  metadata.json          # KPackage metadata (Plasma 6 JSON format)
  contents/
    defaults             # ColorScheme, Icons.Theme, Wallpaper mapping
    previews/preview.png # 480×270 thumbnail for System Settings
    colors/              # RosePineDawnCustom.colors
    wallpapers/          # 4K wallpaper sub-package

rose-pine-main/          # symmetric (Papirus-Dark, RosePineCustom, dark wallpaper)
```

## Install (standalone, outside this dotfiles repo)

```bash
git clone https://github.com/DerTechie/dotfiles.git
cd dotfiles
kpackagetool6 --type Plasma/LookAndFeel --install themes/rose-pine-dawn
kpackagetool6 --type Plasma/LookAndFeel --install themes/rose-pine-main
plasma-apply-lookandfeel --apply org.dertechie.rose-pine-dawn   # or rose-pine-main
```

## Native day/night auto-switch (Plasma 6.5+)

```bash
kwriteconfig6 --file kdeglobals --group KDE --key AutomaticLookAndFeel true
kwriteconfig6 --file kdeglobals --group KDE --key DefaultLightLookAndFeel org.dertechie.rose-pine-dawn
kwriteconfig6 --file kdeglobals --group KDE --key DefaultDarkLookAndFeel  org.dertechie.rose-pine-main
```

Requires **Location Services enabled** (System Settings → Privacy → Location)
so `plasma-knighttimed` can compute sunrise/sunset via `geoclue2`.

## Publishing to the KDE Store

Each `rose-pine-*/` directory is self-contained and tar.gz-uploadable:

```bash
tar -czf rose-pine-dawn.tar.gz -C themes rose-pine-dawn
# Upload to https://store.kde.org/  (category: Plasma Look-and-Feel)
```

## Prior art / credits

- Palette: [rose-pine/palette](https://github.com/rose-pine/palette) (MIT)
- Wallpapers: [rose-pine/wallpapers](https://github.com/rose-pine/wallpapers) (MIT)
- [kelpwave/Rose-pine-for-KDE](https://github.com/kelpwave/Rose-pine-for-KDE)
  was considered for vendoring but lacks a LICENSE file and is Moon-only.
  These themes are authored independently.

## License

MIT — see `LICENSE` inside each bundle.
