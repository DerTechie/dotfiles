alias grep='grep --color=auto'
alias ls='eza --icons --group-directories-first'
alias ll='eza -lh --icons --git --group-directories-first'
alias la='eza -a --icons --group-directories-first'
alias lt='eza --tree --level=2 --icons'
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'
alias docker=podman
