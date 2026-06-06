# fzf previews — the `ble-import` lines live in ~/.config/blesh/init.sh
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always --icons {} | head -200'"

# Per-command preview for **<TAB> completion (cd -> eza tree, files -> bat)
_fzf_comprun() {
	local command=$1; shift
	case "$command" in
		cd)           fzf --preview 'eza --tree --color=always --icons {} | head -200' "$@" ;;
		export|unset) fzf --preview "eval 'echo \$'{}"                                 "$@" ;;
		ssh)          fzf --preview 'dig {}'                                           "$@" ;;
		*)            fzf --preview 'bat -n --color=always --line-range :500 {}'       "$@" ;;
	esac
}
