# ~/.config/blesh/init.sh

# --- fzf integration (preview opts + _fzf_comprun live in ~/.config/bash/rc.d/50-fzf.sh) ---
ble-import -d integration/fzf-completion
ble-import -d integration/fzf-key-bindings

# --- Rosé Pine (main) — minimal face overrides ---
ble-face auto_complete='fg=#6e6a86'
ble-face syntax_default='fg=#e0def4'
ble-face syntax_command='fg=#31748f'
ble-face syntax_quotation='fg=#f6c177'
ble-face syntax_quoted='fg=#f6c177'
ble-face syntax_comment='fg=#6e6a86,italic'
ble-face syntax_error='fg=#eb6f92'
ble-face region='bg=#403d52'
