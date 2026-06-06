HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend cmdhist
PROMPT_COMMAND='history -a'
