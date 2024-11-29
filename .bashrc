#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

if [ -f ~/.bash_prompt ]; then
	. ~/.bash_prompt
fi


hyfetch

##################################################

export VISUAL=vim;
export EDITOR=vim;


# BASH COMMANDS

alias ls='ls --color=auto'
alias grep='grep --color=auto'
# PS1='[\u@\h \W]\$ '
alias ll='ls -alh --color=auto'

alias v='vim'
alias suv='sudo vim'
alias r='ranger'
alias sur='sudo ranger'

alias bashrc='vim .bashrc'
alias i3config='vim ~/.config/i3/config'
alias polybarconfig='vim ~/.config/polybar/config.ini'
alias polybarmodules='vim ~/.config/polybar/modules.ini'

alias cls='clear'

# CODE COMMANDS

alias scheme='cd ~/Code/scheme'
alias haskell='cd ~/Code/haskell'
alias prolog='cd ~/Code/prolog'

# PACMAN COMMANDS

alias upd='sudo pacman -Syu --color=auto'
alias pac='sudo pacman -S --color=auto'
alias pacrm='sudo pacman -R --color=auto'
alias pacs='sudo pacman -Ss --color=auto'
alias pacc='sudo pacman -Sc --color=auto'

alias yay='yay --color=auto'
#alias yays='yay -Ss --color=auto'
#alias yayrm='yay -R --color=auto'

# GIT COMMANDS

alias gs="git status"
alias gpull="git pull"
alias gfetch="git fetch"
alias gpush="git push"
alias ga="git add"

function gcm () {
	git commit -m "$1"
}

export -f gcm

# GIT: OBSIDIAN

alias grotta="cd ~/Vaults/grotta-di-nepero"


# POWER SAVING

alias tlp='sudo tlp'
alias powertop='sudo powertop'

alias normalmode='sudo cpupower frequency-set -g schedutil'
alias powersavemode='sudo cpupower frequency-set -g powersave'

# MISC UTILITY

alias poweroff='sudo pacman -Syu --color=auto && poweroff'
alias forceoff='poweroff'
alias reboot='sudo pacman -Syu --color=auto && reboot'
alias forcereboot='reboot'
# i am fucking stupid and hate npm
# alias nora='cd /home/giovanni/.local/share/Nora && npm start'
alias koel='cd /home/giovanni/.local/share/koel && php artisan serve'

alias archclean="/home/giovanni/.local/bin/cleaner.sh"

# PATH
# ...
