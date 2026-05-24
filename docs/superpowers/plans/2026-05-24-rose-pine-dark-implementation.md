# Rose Pine dark theme + day/night auto-switch — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Rose Pine main (dark) Global Theme alongside Rose Pine Dawn, and let Plasma 6.5+ swap the entire desktop (color scheme, icons, wallpaper, Ghostty, running Neovim) at sunrise/sunset with no third-party scheduler.

**Architecture:** Two `org.dertechie.rose-pine-*` Look-and-Feel bundles live in a publishable top-level `themes/` directory. `install.sh` installs them via `kpackagetool6` and enables Plasma's native auto-switch via four `kdeglobals [KDE]` keys. Ghostty already reacts to the portal preference; Neovim reacts via CSI 2031 + an `OptionSet background` autocmd. Konsave's scope shrinks because theme assets move out of `~/.local/share/`.

**Tech Stack:** Bash + `kpackagetool6` + `kwriteconfig6` (install.sh), KDE Look-and-Feel package format (JSON metadata + INI `defaults`), `.colors` files, Lua (Neovim), chezmoi (deployment), konsave (Plasma state snapshot).

**Spec reference:** [`docs/superpowers/specs/2026-05-24-rose-pine-dark-design.md`](../specs/2026-05-24-rose-pine-dark-design.md)

---

## Scope notes

- **No test framework.** This repo has no automated tests; the deliverable is verified by inspecting config files, running `kpackagetool6 --list`, querying the freedesktop appearance portal via `gdbus`, and eyeballing Plasma. The plan substitutes concrete verification commands for the TDD red/green cycle.
- **Live system is the rice author's machine.** Plasma 6.6.5 is already running. Theme installs and `kwriteconfig6` calls take effect against the live session. Re-runs must remain idempotent.
- **Resolved during writing-plans:**
  - Wallpapers: 4K images from [`rose-pine/wallpapers`](https://github.com/rose-pine/wallpapers) (MIT). Specific files chosen in Task 2 / Task 3 by listing the repo's 4K directory and picking one Dawn-toned and one Main-toned image at 3840×2160.
  - Dawn `.colors`: reuse the existing `~/.local/share/color-schemes/RosePineDawnCustom.colors` (with one fix: the file's `[General] ColorScheme=` field reads `CatppuccinLatteLavender` — a leftover artifact from how it was saved. Set it to `RosePineDawnCustom` when copying into the bundle).
  - Main `.colors`: authored fresh from the rose-pine/palette dark palette using the role mapping defined in Task 1.
- **Deferred to implementation (not blocking):** whether `plasma-apply-lookandfeel --apply` is necessary once `AutomaticLookAndFeel=true` is set. Task 5 keeps the call with `|| true`; Task 11 verifies and removes it if redundant.

## File structure

Files this plan creates or modifies:

```
themes/                                            (NEW, top-level, not chezmoi-managed)
├── README.md                                       (NEW)
├── rose-pine-dawn/                                 (NEW)
│   ├── LICENSE                                     (NEW, MIT)
│   ├── metadata.json                               (NEW)
│   └── contents/
│       ├── defaults                                (NEW, INI)
│       ├── previews/preview.png                    (NEW, 480×270)
│       ├── colors/RosePineDawnCustom.colors        (NEW, copy of existing + [General] fix)
│       └── wallpapers/rose-pine-dawn/
│           ├── metadata.json                       (NEW)
│           └── contents/
│               ├── screenshot.png                  (NEW, optional 1920×1080 preview)
│               └── images/3840x2160.png            (NEW, from rose-pine/wallpapers)
└── rose-pine-main/                                 (NEW, symmetric)
    ├── LICENSE                                     (NEW, MIT)
    ├── metadata.json                               (NEW)
    └── contents/
        ├── defaults                                (NEW, INI)
        ├── previews/preview.png                    (NEW)
        ├── colors/RosePineCustom.colors            (NEW, fresh from palette)
        └── wallpapers/rose-pine-main/
            ├── metadata.json                       (NEW)
            └── contents/
                ├── screenshot.png                  (NEW, optional)
                └── images/3840x2160.png            (NEW, from rose-pine/wallpapers)

install.sh                                          (MODIFY)
.chezmoiignore                                      (MODIFY — add `themes` so it isn't applied to $HOME)
dot_config/ghostty/config.ghostty                   (MODIFY — `dark:Rose Pine Moon` → `dark:Rose Pine`)
dot_config/nvim/lua/plugins/colorscheme.lua         (MODIFY — read vim.o.background)
dot_config/nvim/lua/config/autocmds.lua             (MODIFY — append OptionSet handler)
konsave/rose-pine-dawn.knsv                         (RE-EXPORT — reduced scope)
CLAUDE.md                                           (MODIFY — themes/ + konsave scope)
README.md                                           (MODIFY — stack section)
```

## Color role mapping (locked in)

Used by Task 1 to author the Main `.colors` file. Dawn reuses the existing file as-is (except the `[General]` fix). The mapping is symmetric: same KDE role gets the same Rose Pine palette role on both sides.

| KDE role (group → key) | Rose Pine role | Dawn (existing) | Main (target) |
|---|---|---|---|
| `Colors:Window` → `BackgroundNormal` | `base` | 250,244,237 | 25,23,36 |
| `Colors:Window` → `BackgroundAlternate` | `overlay` | 242,233,225 | 38,35,58 |
| `Colors:View` → `BackgroundNormal` | `surface` | 255,250,243 | 31,29,46 |
| `Colors:View` → `BackgroundAlternate` | `base` | 250,244,237 | 25,23,36 |
| `Colors:Button` → `BackgroundNormal` | `overlay` | 242,233,225 | 38,35,58 |
| `Colors:Button` → `BackgroundAlternate` | `highlightMed` | 223,218,217 | 64,61,82 |
| `Colors:Selection` → `BackgroundNormal` | `highlightMed` | 223,218,217 | 64,61,82 |
| `Colors:Selection` → `BackgroundAlternate` | `highlightLow` | 244,237,232 | 33,32,46 |
| `Colors:Tooltip` → `BackgroundNormal` | `surface` | 242,233,225 | 31,29,46 |
| All groups → `ForegroundNormal` (View/Window) | `text` | 87,82,121 | 224,222,244 |
| All groups → `ForegroundNormal` (Button/Tooltip) | `text` (slightly muted in Dawn) | 68,65,90 / 87,82,121 | 224,222,244 |
| All groups → `ForegroundInactive` | `subtle` | 121,117,147 | 144,140,170 |
| All groups → `ForegroundActive` | `gold` | 234,157,52 | 246,193,119 |
| All groups → `ForegroundLink` | `rose` | 215,130,126 | 235,188,186 |
| All groups → `ForegroundVisited` | `love` | 180,99,122 | 235,111,146 |
| All groups → `ForegroundNeutral` | `gold` | 234,157,52 | 246,193,119 |
| All groups → `ForegroundNegative` | (Dawn red / Main lighter love) | 234,64,52 | 246,127,119 |
| All groups → `ForegroundPositive` | (palette green) | 86,159,97 | 156,216,165 |
| All groups → `DecorationFocus` | `pine` (Dawn) / `foam` (Main) | 62,143,176 | 156,207,216 |
| All groups → `DecorationHover` | `highlightHigh` | 206,202,205 | 82,79,103 |
| `WM` → `activeBackground` | `pine` | 40,105,131 | 49,116,143 |
| `WM` → `activeForeground` | `surface` (Dawn) / `text` (Main) | 255,250,243 | 224,222,244 |
| `WM` → `inactiveBackground` | `overlay` | 242,233,225 | 38,35,58 |
| `WM` → `inactiveForeground` | `text` (Dawn) / `subtle` (Main) | 87,82,121 | 144,140,170 |
| `Complementary:Window` → `BackgroundNormal` | Dawn's `text` flipped to Main's `text`-on-dark | 68,65,90 | 224,222,244 |
| `Complementary:Window` → `ForegroundNormal` | (text on inverted bg) | 224,222,244 | 25,23,36 |

Decimal RGB values come from the [rose-pine/palette](https://github.com/rose-pine/palette) docs. The reasoning for picking `pine` for Dawn's focus accent and `foam` for Main's focus accent is contrast on each background; both are members of the official palette so the visual identity holds.

## Resolution / progressive verification

After each task, the implementer should:
1. `git status` to confirm the diff matches the task scope.
2. Run the task's explicit verification commands; only commit if they pass.
3. Open the changed file in `bat`/`cat` if a manual eyeball is the verification.

The success criteria from the spec collapse into Task 11 (final end-to-end).

---

## Task 1: Scaffold `themes/` and author both color schemes

**Files:**
- Create: `themes/rose-pine-dawn/contents/colors/RosePineDawnCustom.colors`
- Create: `themes/rose-pine-main/contents/colors/RosePineCustom.colors`
- Modify: `.chezmoiignore` (add `themes` so chezmoi doesn't try to copy it into `$HOME`)
- Source reference: `~/.local/share/color-schemes/RosePineDawnCustom.colors` (existing)

- [ ] **Step 1: Create the `themes/` directory skeleton**

```bash
cd /home/dertechie/Repositories/github.com/DerTechie/dotfiles
mkdir -p themes/rose-pine-dawn/contents/{colors,previews,wallpapers/rose-pine-dawn/contents/images}
mkdir -p themes/rose-pine-main/contents/{colors,previews,wallpapers/rose-pine-main/contents/images}
```

- [ ] **Step 2: Add `themes` to `.chezmoiignore`**

Read the current `.chezmoiignore`. Append `themes` on a new line, preserving existing entries and alphabetical position (between `packages` and any trailing entry). Resulting file:

```
README.md
LICENSE
.gitignore
install.sh
packages
konsave
themes
docs
```

(Match the existing entry order rather than re-sorting.)

- [ ] **Step 3: Copy the existing Dawn `.colors` into the bundle and fix `[General] ColorScheme`**

```bash
cp ~/.local/share/color-schemes/RosePineDawnCustom.colors \
   themes/rose-pine-dawn/contents/colors/RosePineDawnCustom.colors

sed -i 's/^ColorScheme=CatppuccinLatteLavender$/ColorScheme=RosePineDawnCustom/' \
   themes/rose-pine-dawn/contents/colors/RosePineDawnCustom.colors
```

Verify the fix landed:

```bash
grep '^ColorScheme=' themes/rose-pine-dawn/contents/colors/RosePineDawnCustom.colors
```

Expected output:

```
ColorScheme=RosePineDawnCustom
```

- [ ] **Step 4: Author `RosePineCustom.colors` for Main**

Create `themes/rose-pine-main/contents/colors/RosePineCustom.colors` with this content (palette values from the role-mapping table above; structure matches Dawn's file 1:1 so System Settings renders both identically):

```ini
[ColorEffects:Disabled]
Color=25,23,36
ColorAmount=0.47500000000000003
ColorEffect=2
ContrastAmount=0
ContrastEffect=0
IntensityAmount=-0.7000000000000001
IntensityEffect=0

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=33,32,46
ColorAmount=0.5
ColorEffect=3
ContrastAmount=0
ContrastEffect=0
Enable=false
IntensityAmount=0
IntensityEffect=0

[Colors:Button]
BackgroundAlternate=64,61,82
BackgroundNormal=38,35,58
DecorationFocus=156,207,216
DecorationHover=82,79,103
ForegroundActive=246,193,119
ForegroundInactive=144,140,170
ForegroundLink=235,188,186
ForegroundNegative=246,127,119
ForegroundNeutral=246,193,119
ForegroundNormal=224,222,244
ForegroundPositive=156,216,165
ForegroundVisited=235,111,146

[Colors:Complementary]
BackgroundAlternate=64,61,82
BackgroundNormal=224,222,244
DecorationFocus=156,207,216
DecorationHover=144,140,170
ForegroundActive=234,157,52
ForegroundInactive=121,117,147
ForegroundLink=215,130,126
ForegroundNegative=234,64,52
ForegroundNeutral=234,157,52
ForegroundNormal=25,23,36
ForegroundPositive=86,159,97
ForegroundVisited=180,99,122

[Colors:Selection]
BackgroundAlternate=33,32,46
BackgroundNormal=64,61,82
DecorationFocus=156,207,216
DecorationHover=82,79,103
ForegroundActive=246,193,119
ForegroundInactive=144,140,170
ForegroundLink=235,188,186
ForegroundNegative=246,127,119
ForegroundNeutral=246,193,119
ForegroundNormal=224,222,244
ForegroundPositive=156,216,165
ForegroundVisited=235,111,146

[Colors:Tooltip]
BackgroundAlternate=64,61,82
BackgroundNormal=31,29,46
DecorationFocus=156,207,216
DecorationHover=82,79,103
ForegroundActive=246,193,119
ForegroundInactive=144,140,170
ForegroundLink=235,188,186
ForegroundNegative=246,127,119
ForegroundNeutral=246,193,119
ForegroundNormal=224,222,244
ForegroundPositive=156,216,165
ForegroundVisited=235,111,146

[Colors:View]
BackgroundAlternate=25,23,36
BackgroundNormal=31,29,46
DecorationFocus=156,207,216
DecorationHover=82,79,103
ForegroundActive=246,193,119
ForegroundInactive=144,140,170
ForegroundLink=235,188,186
ForegroundNegative=246,127,119
ForegroundNeutral=246,193,119
ForegroundNormal=224,222,244
ForegroundPositive=156,216,165
ForegroundVisited=235,111,146

[Colors:Window]
BackgroundAlternate=38,35,58
BackgroundNormal=25,23,36
DecorationFocus=156,207,216
DecorationHover=82,79,103
ForegroundActive=246,193,119
ForegroundInactive=144,140,170
ForegroundLink=235,188,186
ForegroundNegative=246,127,119
ForegroundNeutral=246,193,119
ForegroundNormal=224,222,244
ForegroundPositive=156,216,165
ForegroundVisited=235,111,146

[General]
ColorScheme=RosePineCustom
Name=Rose Pine Custom
TintFactor=0.14
TitlebarIsAccentColored=true
shadeSortColumn=true

[KDE]
contrast=1

[WM]
activeBackground=49,116,143
activeBlend=224,222,244
activeForeground=224,222,244
inactiveBackground=38,35,58
inactiveBlend=144,140,170
inactiveForeground=144,140,170
```

- [ ] **Step 5: Verify both `.colors` files preview in System Settings → Colors**

Install both into the live session so System Settings picks them up:

```bash
mkdir -p ~/.local/share/color-schemes
cp themes/rose-pine-dawn/contents/colors/RosePineDawnCustom.colors ~/.local/share/color-schemes/
cp themes/rose-pine-main/contents/colors/RosePineCustom.colors ~/.local/share/color-schemes/

plasma-apply-colorscheme RosePineCustom
```

Expected: desktop flips to Rose Pine Main (dark) palette within ~1s. Switch back:

```bash
plasma-apply-colorscheme RosePineDawnCustom
```

If either fails with "could not find color scheme", the file name (without `.colors`) must match the `ColorScheme=` field inside. Re-check Step 3 / Step 4.

- [ ] **Step 6: Commit**

```bash
git add themes/rose-pine-dawn/contents/colors/RosePineDawnCustom.colors \
        themes/rose-pine-main/contents/colors/RosePineCustom.colors \
        .chezmoiignore
git commit -m "themes: add Rose Pine Dawn + Main color schemes"
```

---

## Task 2: Build the `rose-pine-dawn` Look-and-Feel bundle

**Files:**
- Create: `themes/rose-pine-dawn/metadata.json`
- Create: `themes/rose-pine-dawn/contents/defaults`
- Create: `themes/rose-pine-dawn/LICENSE`
- Create: `themes/rose-pine-dawn/contents/wallpapers/rose-pine-dawn/metadata.json`
- Create: `themes/rose-pine-dawn/contents/wallpapers/rose-pine-dawn/contents/images/3840x2160.png`
- Create: `themes/rose-pine-dawn/contents/previews/preview.png` (480×270 PNG; can be a Plasma screenshot or simply a downscaled wallpaper crop)

- [ ] **Step 1: Write `metadata.json`**

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

Save to `themes/rose-pine-dawn/metadata.json`.

- [ ] **Step 2: Write the `defaults` INI**

Save to `themes/rose-pine-dawn/contents/defaults`:

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

- [ ] **Step 3: Write the bundle `LICENSE` (MIT)**

Save to `themes/rose-pine-dawn/LICENSE`:

```
MIT License

Copyright (c) 2026 Mike Esser

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 4: Pick + download a 4K Dawn wallpaper from rose-pine/wallpapers**

List the 4K directory on GitHub to see what's available:

```bash
curl -sL https://api.github.com/repos/rose-pine/wallpapers/contents/4k \
  | python -c 'import json,sys; [print(e["name"]) for e in json.load(sys.stdin)]'
```

(If the `4k/` directory has been reorganized, fall back to `curl -sL https://api.github.com/repos/rose-pine/wallpapers/contents | python -c '...'` and locate any Dawn-toned file ≥ 3840×2160. Dawn-toned files typically have `dawn` in the filename.)

Pick one Dawn-toned PNG (filename containing `dawn`). Download it to the bundle:

```bash
DAWN_FILE="<chosen filename from listing>"
curl -sL -o themes/rose-pine-dawn/contents/wallpapers/rose-pine-dawn/contents/images/3840x2160.png \
  "https://raw.githubusercontent.com/rose-pine/wallpapers/main/4k/$DAWN_FILE"
```

Verify dimensions (target is 3840×2160 — must be exactly this since the file path is the resolution KDE looks up):

```bash
identify themes/rose-pine-dawn/contents/wallpapers/rose-pine-dawn/contents/images/3840x2160.png
```

Expected: `... PNG 3840x2160 ...`. If the chosen file is a different resolution, either pick a different file from the listing or resize:

```bash
convert "<source>" -resize 3840x2160^ -gravity center -extent 3840x2160 \
  themes/rose-pine-dawn/contents/wallpapers/rose-pine-dawn/contents/images/3840x2160.png
```

- [ ] **Step 5: Write the wallpaper `metadata.json`**

Save to `themes/rose-pine-dawn/contents/wallpapers/rose-pine-dawn/metadata.json`:

```json
{
  "KPlugin": {
    "Id": "rose-pine-dawn",
    "Name": "Rosé Pine Dawn",
    "Authors": [{ "Name": "rose-pine contributors" }],
    "License": "MIT",
    "Version": "1.0"
  }
}
```

- [ ] **Step 6: Create a preview image (480×270 PNG)**

Plasma's System Settings → Global Themes uses `contents/previews/preview.png` (480×270) for the picker thumbnail.

The simplest preview is a downscaled crop of the wallpaper:

```bash
convert themes/rose-pine-dawn/contents/wallpapers/rose-pine-dawn/contents/images/3840x2160.png \
  -resize 480x270^ -gravity center -extent 480x270 \
  themes/rose-pine-dawn/contents/previews/preview.png
```

Verify:

```bash
identify themes/rose-pine-dawn/contents/previews/preview.png
```

Expected: `... PNG 480x270 ...`.

(A wallpaper screenshot looks cheap; if you want a real preview you can grab one later via `spectacle --fullscreen --background --pointer=false --output=...` after applying the theme.)

- [ ] **Step 7: Install the bundle into the live session and verify**

```bash
kpackagetool6 --type Plasma/LookAndFeel --install themes/rose-pine-dawn
kpackagetool6 --type Plasma/LookAndFeel --list 2>/dev/null | grep '^org.dertechie.rose-pine-dawn$'
```

Expected: the grep matches (exit 0).

Apply the theme to the live session:

```bash
plasma-apply-lookandfeel --apply org.dertechie.rose-pine-dawn
```

Expected: desktop flips to Dawn (color scheme, Papirus-Light icons, wallpaper). Open System Settings → Global Themes and confirm "Rosé Pine Dawn" appears with a preview thumbnail.

- [ ] **Step 8: Commit**

```bash
git add themes/rose-pine-dawn
git commit -m "themes: add Rose Pine Dawn Global Theme bundle"
```

---

## Task 3: Build the `rose-pine-main` Look-and-Feel bundle (symmetric to Task 2)

**Files:**
- Create: `themes/rose-pine-main/metadata.json`
- Create: `themes/rose-pine-main/contents/defaults`
- Create: `themes/rose-pine-main/LICENSE`
- Create: `themes/rose-pine-main/contents/wallpapers/rose-pine-main/metadata.json`
- Create: `themes/rose-pine-main/contents/wallpapers/rose-pine-main/contents/images/3840x2160.png`
- Create: `themes/rose-pine-main/contents/previews/preview.png`

- [ ] **Step 1: Write `metadata.json`**

Save to `themes/rose-pine-main/metadata.json`:

```json
{
  "KPackageStructure": "Plasma/LookAndFeel",
  "KPlugin": {
    "Id": "org.dertechie.rose-pine-main",
    "Name": "Rosé Pine",
    "Description": "Soho-vibe dark theme based on the Rosé Pine main palette",
    "Authors": [{ "Name": "Mike Esser", "Email": "info@dertechie.de" }],
    "Category": "Plasma Look and Feel",
    "License": "MIT",
    "Version": "1.0",
    "Website": "https://github.com/DerTechie/dotfiles/tree/main/themes"
  }
}
```

- [ ] **Step 2: Write the `defaults` INI**

Save to `themes/rose-pine-main/contents/defaults`:

```ini
[kdeglobals][KDE]
LookAndFeelPackage=org.dertechie.rose-pine-main

[kdeglobals][General]
ColorScheme=RosePineCustom

[kdeglobals][Icons]
Theme=Papirus-Dark

[plasmarc][Theme]
name=default

[kwinrc][org.kde.kdecoration2]
library=org.kde.breeze
theme=Breeze

[Wallpaper]
Image=rose-pine-main
```

- [ ] **Step 3: Write the bundle `LICENSE` (MIT)**

Copy the LICENSE from Task 2 verbatim to `themes/rose-pine-main/LICENSE`. Same copyright holder, same year.

```bash
cp themes/rose-pine-dawn/LICENSE themes/rose-pine-main/LICENSE
```

- [ ] **Step 4: Pick + download a 4K Main wallpaper from rose-pine/wallpapers**

Re-use the listing from Task 2 Step 4 (the file is in `4k/`). Pick a Main-toned PNG (filename typically contains `rose-pine` without `dawn`/`moon` qualifiers, or contains `main`). Avoid `moon` variants — those are intentionally excluded from this rice.

```bash
MAIN_FILE="<chosen filename from listing>"
curl -sL -o themes/rose-pine-main/contents/wallpapers/rose-pine-main/contents/images/3840x2160.png \
  "https://raw.githubusercontent.com/rose-pine/wallpapers/main/4k/$MAIN_FILE"

identify themes/rose-pine-main/contents/wallpapers/rose-pine-main/contents/images/3840x2160.png
```

Expected: `... PNG 3840x2160 ...`. Resize with the same `convert` invocation as Task 2 Step 4 if needed.

- [ ] **Step 5: Write the wallpaper `metadata.json`**

Save to `themes/rose-pine-main/contents/wallpapers/rose-pine-main/metadata.json`:

```json
{
  "KPlugin": {
    "Id": "rose-pine-main",
    "Name": "Rosé Pine",
    "Authors": [{ "Name": "rose-pine contributors" }],
    "License": "MIT",
    "Version": "1.0"
  }
}
```

- [ ] **Step 6: Create the preview thumbnail**

```bash
convert themes/rose-pine-main/contents/wallpapers/rose-pine-main/contents/images/3840x2160.png \
  -resize 480x270^ -gravity center -extent 480x270 \
  themes/rose-pine-main/contents/previews/preview.png

identify themes/rose-pine-main/contents/previews/preview.png
```

Expected: `... PNG 480x270 ...`.

- [ ] **Step 7: Install the bundle and verify the visual flip**

```bash
kpackagetool6 --type Plasma/LookAndFeel --install themes/rose-pine-main
kpackagetool6 --type Plasma/LookAndFeel --list 2>/dev/null \
  | grep -E '^org\.dertechie\.rose-pine-(dawn|main)$'
```

Expected: both `org.dertechie.rose-pine-dawn` and `org.dertechie.rose-pine-main` appear.

Apply Main and confirm the full dark flip:

```bash
plasma-apply-lookandfeel --apply org.dertechie.rose-pine-main
```

Expected: desktop flips dark — color scheme, icons (Papirus-Dark), wallpaper all change. Switch back to Dawn:

```bash
plasma-apply-lookandfeel --apply org.dertechie.rose-pine-dawn
```

- [ ] **Step 8: Commit**

```bash
git add themes/rose-pine-main
git commit -m "themes: add Rose Pine Main Global Theme bundle"
```

---

## Task 4: Add `themes/README.md`

**Files:**
- Create: `themes/README.md`

- [ ] **Step 1: Write the README**

Save to `themes/README.md`:

````markdown
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
````

- [ ] **Step 2: Verify the README renders cleanly**

```bash
ls themes/
cat themes/README.md | head -5
```

Expected: file exists, the top heading reads `# Rosé Pine Global Themes for KDE Plasma 6`.

- [ ] **Step 3: Commit**

```bash
git add themes/README.md
git commit -m "themes: add README for Rose Pine Global Theme packages"
```

---

## Task 5: Update `install.sh` for theme install + auto-switch

**Files:**
- Modify: `install.sh:55-66` (replace the "Importing Konsave" / "Applying color scheme" / "Rebuilding icon caches" / "Done" tail)

- [ ] **Step 1: Read the current tail of `install.sh` to lock in line numbers**

```bash
sed -n '49,66p' install.sh
```

Expected current lines 49-66:

```
echo "==> Installing konsave via pipx"
if ! pipx list --short 2>/dev/null | grep -q '^konsave '; then
  pipx install konsave
fi
export PATH="$HOME/.local/bin:$PATH"

echo "==> Importing Konsave profile"
konsave -i "$REPO_DIR/konsave/rose-pine-dawn.knsv"
konsave -a rose-pine-dawn

echo "==> Applying color scheme by name"
plasma-apply-colorscheme RosePineDawnCustom || true

echo "==> Rebuilding icon caches"
kbuildsycoca6 --noincremental || true

echo "==> Done. Log out and back in to apply Plasma settings and group changes."
```

- [ ] **Step 2: Replace the `Applying color scheme by name` block with the Look-and-Feel install + auto-switch block**

Edit `install.sh` so the file from line 55 onward reads:

```bash
echo "==> Importing Konsave profile"
konsave -i "$REPO_DIR/konsave/rose-pine-dawn.knsv"
konsave -a rose-pine-dawn

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

echo "==> Rebuilding icon caches"
kbuildsycoca6 --noincremental || true

echo "==> Done. Log out and back in to apply Plasma settings and group changes."
```

The key changes:
- Remove `echo "==> Applying color scheme by name"` + `plasma-apply-colorscheme RosePineDawnCustom || true`.
- Insert `==> Installing Rosé Pine Global Themes` + `==> Enabling automatic day/night Global Theme switching` + `==> Seeding initial Global Theme` blocks between the konsave block and the `==> Rebuilding icon caches` block.

Use the Edit tool to replace the old block with the new one. The `set -euo pipefail` at the top must remain — the for-loop's exit status is the last command's, so a failing `kpackagetool6` will abort the script (correct behavior).

- [ ] **Step 3: Verify the edit landed cleanly**

```bash
bash -n install.sh
```

Expected: no output (syntax OK).

```bash
grep -n 'plasma-apply-colorscheme' install.sh
```

Expected: empty (the old line is gone).

```bash
grep -nE 'kpackagetool6|AutomaticLookAndFeel|plasma-apply-lookandfeel' install.sh
```

Expected: at least 5 matches reflecting the new block.

- [ ] **Step 4: Dry-run idempotency on the live system**

Before re-running the whole script, verify the new commands behave on an already-themed system (which `install.sh` will encounter on any second run after Task 2/3 already ran them):

```bash
# kpackagetool6 --upgrade on an installed package
kpackagetool6 --type Plasma/LookAndFeel --upgrade themes/rose-pine-dawn

# kwriteconfig6 is idempotent by design — re-running sets the same value
kwriteconfig6 --file kdeglobals --group KDE --key AutomaticLookAndFeel true
kwriteconfig6 --file kdeglobals --group KDE --key DefaultLightLookAndFeel org.dertechie.rose-pine-dawn
kwriteconfig6 --file kdeglobals --group KDE --key DefaultDarkLookAndFeel  org.dertechie.rose-pine-main

# Verify
kreadconfig6 --file kdeglobals --group KDE --key AutomaticLookAndFeel
kreadconfig6 --file kdeglobals --group KDE --key DefaultLightLookAndFeel
kreadconfig6 --file kdeglobals --group KDE --key DefaultDarkLookAndFeel
```

Expected output of the three `kreadconfig6` calls:

```
true
org.dertechie.rose-pine-dawn
org.dertechie.rose-pine-main
```

- [ ] **Step 5: Verify the auto-switch daemon picks it up**

```bash
systemctl --user status plasma-knighttimed.service 2>&1 | head -5
```

If the service was `inactive (dead)` before Task 5, it should transition to `active (running)` after `AutomaticLookAndFeel=true` is written (Plasma's KDED launches it on demand). If it stays dead, log out + back into Plasma and re-check; the unit is started by Plasma's session manager.

Verify the portal preference matches the seeded theme:

```bash
gdbus call --session \
  --dest org.freedesktop.portal.Desktop \
  --object-path /org/freedesktop/portal/desktop \
  --method org.freedesktop.portal.Settings.Read \
  org.freedesktop.appearance color-scheme
```

Expected: `(<<uint32 2>>,)` for Dawn (light → portal value 2) or `(<<uint32 1>>,)` for Main (dark → 1). Either is acceptable — what matters is the value matches the currently active theme.

- [ ] **Step 6: Commit**

```bash
git add install.sh
git commit -m "install: switch from plasma-apply-colorscheme to native Global Theme auto-switch"
```

---

## Task 6: Update Ghostty config

**Files:**
- Modify: `dot_config/ghostty/config.ghostty:1`

- [ ] **Step 1: Verify current content**

```bash
cat dot_config/ghostty/config.ghostty
```

Expected:

```
theme = light:Rose Pine Dawn,dark:Rose Pine Moon

font-family = JetBrainsMono Nerd Font
font-size = 13
```

- [ ] **Step 2: Swap `Rose Pine Moon` → `Rose Pine`**

Use the Edit tool to change line 1 from:

```
theme = light:Rose Pine Dawn,dark:Rose Pine Moon
```

to:

```
theme = light:Rose Pine Dawn,dark:Rose Pine
```

- [ ] **Step 3: Apply via chezmoi and verify Ghostty reacts**

```bash
chezmoi apply --source="$(pwd)" ~/.config/ghostty/config.ghostty
diff dot_config/ghostty/config.ghostty ~/.config/ghostty/config.ghostty
```

Expected: empty diff (the deployed file matches the repo file).

Open a fresh Ghostty window. With Plasma in Dawn, the terminal should be on `Rose Pine Dawn`. Run:

```bash
plasma-apply-lookandfeel --apply org.dertechie.rose-pine-main
```

Expected: existing Ghostty windows flip to the `Rose Pine` palette within ~1s (Ghostty subscribes to the portal preference). Switch back to Dawn:

```bash
plasma-apply-lookandfeel --apply org.dertechie.rose-pine-dawn
```

- [ ] **Step 4: Commit**

```bash
git add dot_config/ghostty/config.ghostty
git commit -m "ghostty: switch dark variant from Rose Pine Moon to Rose Pine"
```

---

## Task 7: Wire Neovim to follow `vim.o.background`

**Files:**
- Modify: `dot_config/nvim/lua/plugins/colorscheme.lua` (replace contents)
- Modify: `dot_config/nvim/lua/config/autocmds.lua` (append)

- [ ] **Step 1: Replace `colorscheme.lua`**

Current content (verify before editing):

```lua
return {
  { "rose-pine/neovim", name = "rose-pine" },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "rose-pine-dawn",
    },
  },
}
```

Replace the entire file with:

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

- [ ] **Step 2: Append the autocmd to `autocmds.lua`**

Read the current file:

```bash
cat dot_config/nvim/lua/config/autocmds.lua
```

Expected: an LazyVim template file with only header comments, ending after the last comment line. Append (do not replace) the following block to the end of the file, leaving one blank line between the existing comments and the new code:

```lua

vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "background",
  callback = function()
    local scheme = vim.v.option_new == "dark" and "rose-pine" or "rose-pine-dawn"
    pcall(vim.cmd.colorscheme, scheme)
  end,
})
```

- [ ] **Step 3: Apply via chezmoi and lint**

```bash
chezmoi apply --source="$(pwd)" \
  ~/.config/nvim/lua/plugins/colorscheme.lua \
  ~/.config/nvim/lua/config/autocmds.lua

diff dot_config/nvim/lua/plugins/colorscheme.lua ~/.config/nvim/lua/plugins/colorscheme.lua
diff dot_config/nvim/lua/config/autocmds.lua    ~/.config/nvim/lua/config/autocmds.lua
```

Expected: both diffs empty.

Quick Lua syntax check:

```bash
nvim --headless -c 'luafile ~/.config/nvim/lua/plugins/colorscheme.lua' -c 'qa'
nvim --headless -c 'luafile ~/.config/nvim/lua/config/autocmds.lua' -c 'qa'
```

Expected: both exit 0 with no error output. (The colorscheme file returns a Lazy spec table — running it via `luafile` is harmless; we're only checking the file parses.)

- [ ] **Step 4: Verify the autocmd actually flips the scheme**

Open Neovim inside Ghostty. With Plasma in Dawn, `:colorscheme` should report `rose-pine-dawn`. From another terminal:

```bash
plasma-apply-lookandfeel --apply org.dertechie.rose-pine-main
```

In the running Neovim, run `:colorscheme` again. Expected: `rose-pine`. If it didn't flip:

- Check `:checkhealth` for terminal capability — Ghostty should advertise CSI 2031.
- Check `:set background?` — should now read `dark`.
- If `background` didn't change, Ghostty's CSI 2031 emission may be disabled. As of Ghostty's current builds it's on by default; check with `:lua print(vim.o.background)` immediately after the system flip.

Switch back to Dawn and confirm `:colorscheme` flips back to `rose-pine-dawn`.

- [ ] **Step 5: Commit**

```bash
git add dot_config/nvim/lua/plugins/colorscheme.lua \
        dot_config/nvim/lua/config/autocmds.lua
git commit -m "nvim: follow vim.o.background between rose-pine-dawn and rose-pine"
```

---

## Task 8: Re-export the konsave snapshot with reduced scope

**Files:**
- Modify: `konsave/rose-pine-dawn.knsv` (binary; will be overwritten)

The current snapshot bundles `~/.local/share/color-schemes/*`, `~/.local/share/wallpapers/*`, and `~/.local/share/plasma/look-and-feel/*` via the konsave profile's `export:` section. Those assets now live in `themes/` and are installed by `kpackagetool6`. The snapshot should stop carrying them.

- [ ] **Step 1: Locate and edit the konsave profile config**

The profile is stored at `~/.config/konsave/conf.yaml` (a single YAML file with named profiles). View it:

```bash
cat ~/.config/konsave/conf.yaml
```

Find the `rose-pine-dawn:` profile block. It will have an `export:` list that includes entries like:

```yaml
export:
  - location: $HOME/.local/share/color-schemes
    ...
  - location: $HOME/.local/share/wallpapers
    ...
  - location: $HOME/.local/share/plasma/look-and-feel
    ...
```

Comment out or remove those three `- location:` entries (and their nested keys) from the `rose-pine-dawn:` profile. Leave any other entries (panel state, dolphinrc, kateschema, etc.) untouched. Keep `kdeglobals` — that's where the `[KDE]` auto-switch keys live, and Task 5 wrote them there.

If the profile doesn't have an obvious shape (konsave's YAML structure varies), the alternative is to delete the three relevant directories from the staged profile right before export:

```bash
konsave -s rose-pine-dawn -f
rm -rf ~/.config/konsave/profiles/rose-pine-dawn/local-share/color-schemes \
       ~/.config/konsave/profiles/rose-pine-dawn/local-share/wallpapers \
       ~/.config/konsave/profiles/rose-pine-dawn/local-share/plasma/look-and-feel
```

(Verify the exact path under `~/.config/konsave/profiles/` first — konsave stages profile content under there.)

- [ ] **Step 2: Re-save the profile against the current Plasma state**

```bash
konsave -s rose-pine-dawn -f
```

Expected: prints `Profile saved` or similar.

- [ ] **Step 3: Verify the staged profile carries the new `[KDE]` auto-switch keys**

```bash
grep -A2 '^\[KDE\]' ~/.config/konsave/profiles/rose-pine-dawn/config/kdeglobals 2>/dev/null \
  || grep -A2 '^\[KDE\]' ~/.config/konsave/profiles/rose-pine-dawn/kdeglobals 2>/dev/null
```

(Adjust path if konsave nests differently.) Expected: among the output, the lines:

```
AutomaticLookAndFeel=true
DefaultLightLookAndFeel=org.dertechie.rose-pine-dawn
DefaultDarkLookAndFeel=org.dertechie.rose-pine-main
```

If those keys aren't present, the konsave profile's `entries:` list doesn't include `kdeglobals` and needs to. Add it before re-saving.

- [ ] **Step 4: Export to the repo and rename**

```bash
konsave -e rose-pine-dawn \
  -d "$(pwd)/konsave" \
  -n rose-pine-dawn
```

konsave will write `konsave/rose-pine-dawn_<timestamp>.knsv` despite `-n`. Rename:

```bash
ls -la konsave/
mv konsave/rose-pine-dawn_*.knsv konsave/rose-pine-dawn.knsv
```

Expected (after rename): `ls konsave/` shows only `rose-pine-dawn.knsv` (no timestamped sibling).

- [ ] **Step 5: Verify the file is smaller (sanity check)**

```bash
git diff --stat konsave/rose-pine-dawn.knsv
ls -la konsave/rose-pine-dawn.knsv
```

Expected: the file is smaller than its previous size (the bundled `~/.local/share/{color-schemes,wallpapers,plasma/look-and-feel}` assets are gone). If it's the same size or larger, the export still carries them — re-check Step 1.

- [ ] **Step 6: Commit**

```bash
git add konsave/rose-pine-dawn.knsv
git commit -m "konsave: drop theme assets from snapshot now that themes/ owns them"
```

---

## Task 9: Update `CLAUDE.md`

**Files:**
- Modify: `CLAUDE.md` (repo layout block ~line 13-23; konsave section ~line 51-70; add a `themes/` subsection)

- [ ] **Step 1: Update the "Repo layout" code block**

Locate the layout block in `CLAUDE.md` (around lines 13-23). Add `themes/` between `dot_config/` and `konsave/`. Result:

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

- [ ] **Step 2: Update the prose under "Repo layout" about what konsave bundles**

Current paragraph (around line 25):

> Theme assets under `~/.local/share/` (color schemes, look-and-feel, aurorae, desktoptheme) are bundled into the konsave `.knsv` via its `export:` section, so they're not duplicated under a `dot_local/` tree. If you ever add per-user assets that konsave doesn't capture, put them under `dot_local/` and chezmoi will manage them.

Replace with:

> Plasma Global Themes live in [`themes/`](themes/) as proper KDE Look-and-Feel packages and are installed by `install.sh` via `kpackagetool6`. The konsave `.knsv` no longer bundles `~/.local/share/{color-schemes,wallpapers,plasma/look-and-feel}` — it now carries only panel/widget/dolphin/etc. application state plus the `kdeglobals [KDE]` keys that drive day/night auto-switching. If you ever add per-user assets that neither `themes/` nor konsave captures, put them under `dot_local/` and chezmoi will manage them.

- [ ] **Step 3: Update `.chezmoiignore` reference**

Current line (around line 32):

> Anything that should live in the repo but **not** be applied to `$HOME` must be listed in `.chezmoiignore` (currently: `README.md`, `LICENSE`, `.gitignore`, `install.sh`, `packages`, `konsave`).

Add `themes` to that list:

> Anything that should live in the repo but **not** be applied to `$HOME` must be listed in `.chezmoiignore` (currently: `README.md`, `LICENSE`, `.gitignore`, `install.sh`, `packages`, `konsave`, `themes`, `docs`).

- [ ] **Step 4: Add a new `### Updating a theme bundle` subsection under `## Common tasks`**

Insert after the existing `### Adding a new dotfile` section and before `### Updating the Konsave snapshot`:

````markdown
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
````

- [ ] **Step 5: Update the "Updating the Konsave snapshot" section**

The current section describes konsave as the source of truth for theme assets and references `plasma-apply-colorscheme RosePineDawnCustom` in the post-import step. Both are now wrong. Replace the section body (keep the heading) with:

````markdown
### Updating the Konsave snapshot

`konsave/rose-pine-dawn.knsv` is a binary snapshot of the Plasma configuration.
Since the day/night auto-switch landed, its scope is narrower: panel/widget
layout, dolphin/kate/etc. application state, and the `kdeglobals [KDE]`
auto-switch keys. It no longer bundles color schemes, wallpapers, or
look-and-feel packages — those live in `themes/` as proper KPackage bundles.

After making Plasma changes that should be part of the rice:

```bash
konsave -s rose-pine-dawn -f      # overwrite the named profile with current state
konsave -e rose-pine-dawn \
  -d "$REPO_DIR/konsave" \
  -n rose-pine-dawn               # export to <repo>/konsave/rose-pine-dawn.knsv
```

konsave appends a timestamp to the filename despite `-n`; rename back to
`rose-pine-dawn.knsv` before committing. The file is now smaller than the
pre-themes/ era — expect diffs proportional to what actually changed.

**Pitfall — color scheme must be a *named* scheme.** Plasma 6's first-session
logic can reset `kdeglobals` if the active color scheme is identified only by
`ColorSchemeHash` and not `ColorScheme=NAME`. To ensure the snapshot survives
a fresh install:

1. System Settings → Colors → "Save current colors as new scheme…" → give it
   a name (e.g. `RosePineDawnCustom` / `RosePineCustom`).
2. Apply it (or run `plasma-apply-lookandfeel --apply org.dertechie.rose-pine-dawn`)
   so `kdeglobals [General]` gains a `ColorScheme=` line that names the scheme.
3. Then re-export the konsave snapshot.

`install.sh` runs `plasma-apply-lookandfeel --apply org.dertechie.rose-pine-dawn`
after `konsave -a` to seed the live session; once `AutomaticLookAndFeel=true`
is set, `plasma-knighttimed` takes over for subsequent transitions.
````

- [ ] **Step 6: Verify the diff is sensible**

```bash
git diff CLAUDE.md
```

Expected: changes are localized to the four sections above, with no surprise edits.

- [ ] **Step 7: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md for themes/ directory and reduced konsave scope"
```

---

## Task 10: Update `README.md`

**Files:**
- Modify: `README.md` (Stack section ~line 16-22)

- [ ] **Step 1: Update the Stack section**

Current Stack section (around lines 16-22):

```markdown
## Stack

- **Desktop:** KDE Plasma 6, Rosé Pine Dawn theme
- **Terminal:** Ghostty with Rosé Pine Dawn/Moon (auto-switching)
- **Editor:** Neovim with LazyVim + rose-pine-dawn
- **Icons:** Papirus Light with palebrown folders
- **Fonts:** Inter (UI), JetBrains Mono Nerd Font (terminal, fixed-width)
```

Replace with:

```markdown
## Stack

- **Desktop:** KDE Plasma 6 with native day/night Global Theme auto-switch (Rosé Pine Dawn ↔ Rosé Pine, driven by `plasma-knighttimed` + `geoclue2`)
- **Terminal:** Ghostty with Rosé Pine Dawn/Rosé Pine (follows the freedesktop appearance portal)
- **Editor:** Neovim with LazyVim, flipping rose-pine-dawn ↔ rose-pine via CSI 2031 / `OptionSet background`
- **Icons:** Papirus Light (day) / Papirus Dark (night) with palebrown folders
- **Fonts:** Inter (UI), JetBrains Mono Nerd Font (terminal, fixed-width)
```

- [ ] **Step 2: Add a `Location Services` note under "Manual post-install steps"**

Current section (around lines 29-31):

```markdown
## Manual post-install steps

- **Obsidian** — settings (theme, plugins, hotkeys, appearance) are stored per-vault under `<vault>/.obsidian/` rather than globally, so they're not managed here. After opening a vault, install the Rosé Pine theme via Settings → Appearance → Themes → Manage → search "Rosé Pine".
```

Add a Location Services bullet **before** the Obsidian one (Location is required for the day/night switch to work, so it surfaces first):

```markdown
## Manual post-install steps

- **Enable Location Services** — System Settings → Privacy → Location → enable. `plasma-knighttimed` reads location via `geoclue2` to compute sunrise/sunset. Without this, the Global Theme stays on whichever variant was last applied.
- **Obsidian** — settings (theme, plugins, hotkeys, appearance) are stored per-vault under `<vault>/.obsidian/` rather than globally, so they're not managed here. After opening a vault, install the Rosé Pine theme via Settings → Appearance → Themes → Manage → search "Rosé Pine".
```

- [ ] **Step 3: Update the Credits section**

Current Credits section (around lines 33-39):

```markdown
## Credits

- [Rosé Pine](https://rosepinetheme.com/) palette and themes
- [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) icons
- [LazyVim](https://www.lazyvim.org/) Neovim distribution
- [Konsave](https://github.com/Prayag2/konsave) for Plasma state
- [chezmoi](https://www.chezmoi.io/) for dotfile management
```

Add a wallpapers credit (since `themes/` vendors wallpaper PNGs from `rose-pine/wallpapers`):

```markdown
## Credits

- [Rosé Pine](https://rosepinetheme.com/) palette and themes
- [rose-pine/wallpapers](https://github.com/rose-pine/wallpapers) for the 4K wallpapers bundled in `themes/`
- [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) icons
- [LazyVim](https://www.lazyvim.org/) Neovim distribution
- [Konsave](https://github.com/Prayag2/konsave) for Plasma state
- [chezmoi](https://www.chezmoi.io/) for dotfile management
```

- [ ] **Step 4: Verify the diff**

```bash
git diff README.md
```

Expected: edits localized to the Stack, Manual post-install steps, and Credits sections.

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "docs: update README for day/night auto-switch + wallpapers credit"
```

---

## Task 11: Final end-to-end verification against success criteria

This task runs the success criteria from the spec end-to-end. It produces no new commits unless a regression surfaces.

- [ ] **Step 1: Verify both themes are installed and listed**

```bash
kpackagetool6 --type Plasma/LookAndFeel --list 2>/dev/null \
  | grep -E '^org\.dertechie\.rose-pine-(dawn|main)$'
```

Expected: both lines present.

- [ ] **Step 2: Verify the auto-switch keys are set**

```bash
for k in AutomaticLookAndFeel DefaultLightLookAndFeel DefaultDarkLookAndFeel; do
  printf '%-32s = ' "$k"
  kreadconfig6 --file kdeglobals --group KDE --key "$k"
done
```

Expected:

```
AutomaticLookAndFeel             = true
DefaultLightLookAndFeel          = org.dertechie.rose-pine-dawn
DefaultDarkLookAndFeel           = org.dertechie.rose-pine-main
```

- [ ] **Step 3: Verify manual toggle flips every surface**

Open Ghostty (with Neovim inside, in another tab/pane), then run from a third terminal:

```bash
plasma-apply-lookandfeel --apply org.dertechie.rose-pine-main
sleep 6   # > idle gate (5s)
```

Confirm visually within a few seconds (the idle gate is 5s, so allow > 5s before declaring failure):

- Plasma color scheme → dark
- Icons → Papirus-Dark (open Dolphin if needed to confirm)
- Wallpaper → the Main-toned 4K image
- Ghostty palette → Rose Pine (dark)
- Neovim → `:colorscheme` reports `rose-pine`

Switch back:

```bash
plasma-apply-lookandfeel --apply org.dertechie.rose-pine-dawn
sleep 6
```

Confirm all five surfaces flip back to Dawn.

- [ ] **Step 4: Verify the portal preference matches the active theme**

```bash
gdbus call --session \
  --dest org.freedesktop.portal.Desktop \
  --object-path /org/freedesktop/portal/desktop \
  --method org.freedesktop.portal.Settings.Read \
  org.freedesktop.appearance color-scheme
```

Expected: `(<<uint32 2>>,)` when Dawn is active, `(<<uint32 1>>,)` when Main is active.

- [ ] **Step 5: Verify `plasma-knighttimed` is alive (with Location Services enabled)**

```bash
systemctl --user status plasma-knighttimed.service 2>&1 | grep -E 'Active|Loaded'
```

Expected: `Active: active (running)`. If `inactive (dead)`, either Location Services is off (acceptable — document and move on), or the service needs Plasma to reload (log out + back in).

If Location Services is off, the spec accepts this as a precondition that the README now documents; auto-switching is only expected to fire when geoclue can return a location.

- [ ] **Step 6: Verify `install.sh` re-run is a no-op**

The dangerous one. Re-run the script and confirm nothing visible changes:

```bash
bash install.sh
```

Expected:
- `kpackagetool6 --upgrade` reinstalls both bundles without breaking the live session.
- `kwriteconfig6` overwrites the three keys to their existing values.
- `plasma-apply-lookandfeel --apply org.dertechie.rose-pine-dawn` either re-seeds (if knighttimed hasn't claimed orchestration yet) or is a visual no-op. **Decision point:** if this call has no observable effect on a configured system, leave it in (it's defensive seeding for fresh installs). If it _undoes_ a knighttimed-driven Main → Dawn transition mid-day, remove the line and commit the fix.

Confirm via:

```bash
plasma-apply-lookandfeel --apply org.dertechie.rose-pine-main
sleep 6
bash install.sh
sleep 6
# Did the desktop flip back to Dawn unexpectedly?
```

Expected: knighttimed re-asserts the time-appropriate theme within seconds, so even if `install.sh` briefly flips to Dawn, the system returns to the correct variant. If that doesn't happen — i.e. `install.sh` permanently overrides knighttimed — remove the `plasma-apply-lookandfeel` line from `install.sh` and commit:

```bash
git add install.sh
git commit -m "install: drop redundant Look-and-Feel seed; knighttimed handles it"
```

- [ ] **Step 7: Verify each theme bundle is standalone-installable**

Outside the repo, simulate an outsider installing one bundle directly:

```bash
TMP=$(mktemp -d)
cp -r themes/rose-pine-dawn "$TMP/"
kpackagetool6 --type Plasma/LookAndFeel --upgrade "$TMP/rose-pine-dawn"
plasma-apply-lookandfeel --apply org.dertechie.rose-pine-dawn
rm -rf "$TMP"
```

Expected: install + apply succeed against the copy, with no reference to the parent dotfiles repo.

- [ ] **Step 8: Verify no `darkman` residue in tracked files**

Check only git-tracked files (the local `.claude/settings.local.json` allow-list and historical spec/plan files don't count):

```bash
git ls-files -z \
  | xargs -0 grep -In 'darkman' -- \
        ':!docs/superpowers/specs/*' \
        ':!docs/superpowers/plans/*' \
    || echo "(no matches outside historical docs)"
```

Expected: `(no matches outside historical docs)`. If `install.sh`, `packages/aur.txt`, `CLAUDE.md`, or `README.md` shows up, remove the reference and re-commit before claiming Task 11 done.

- [ ] **Step 9: Sunrise/sunset transition (deferred observational check)**

The full natural sunset transition can't be verified synchronously in one session — it requires waiting until `plasma-knighttimed` fires its next event. Note the next expected transition time:

```bash
journalctl --user -u plasma-knighttimed.service -n 50 2>/dev/null \
  | grep -iE 'sunrise|sunset|transition'
```

Note the next sunrise/sunset in the log. After that time passes (next morning or evening), open System Settings → Colors and Themes briefly to confirm the active variant matches the time of day. If the transition didn't fire on schedule, file a follow-up issue and re-check Location Services.

This step is the only one in the plan that closes out asynchronously; everything else verifies within the implementation session.

---

## Self-review notes

This plan was self-reviewed against the spec. Coverage summary:

- **Two Plasma Global Themes** — Tasks 2 + 3.
- **Themes in top-level `themes/`** — Task 1 (skeleton) + 2/3 (bundles).
- **Native Plasma scheduling** — Task 5 (`kwriteconfig6` keys).
- **Ghostty palette swap** — Task 6.
- **Neovim CSI 2031 + autocmd** — Task 7.
- **No `darkman`** — verified in Task 11 Step 8.
- **No custom Plasma Style / KWin decoration** — Tasks 2/3 `defaults` files leave both at stock Breeze.
- **Color schemes from rose-pine/palette** — Task 1.
- **Konsave's reduced scope** — Task 8.
- **CLAUDE.md edits** — Task 9.
- **README updates** — Task 10.
- **Idempotency** — Task 5 Step 4 + Task 11 Step 6.
- **Standalone-installable bundles** — Task 11 Step 7.

Open question status:

1. Wallpapers — resolved in Tasks 2 + 3 (4K from rose-pine/wallpapers).
2. Color scheme mapping — resolved in the role-mapping table + Task 1 Step 4.
3. `kpackagetool6 --upgrade` semantics on never-installed — handled by the if/else in Task 5 Step 2 and exercised in Task 11 Step 7.
4. `plasma-apply-lookandfeel --apply` vs knighttimed override — settled empirically in Task 11 Step 6.
5. CLAUDE.md edits — Task 9.
