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

alias notes='v /home/giovanni/notes'


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

export PATH=/home/giovanni/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/var/lib/snapd/snap/bin:/home/giovanni/.local/share/pycharm/pycharm-2024.2.1/bin:/opt/idea-IU-243.21565.193/bin:/home/giovanni/.config/eww/src

#PATH="/home/giovanni/perl5/bin${PATH:+:${PATH}}"; export PATH;
#PERL5LIB="/home/giovanni/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
#PERL_LOCAL_LIB_ROOT="/home/giovanni/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
#PERL_MB_OPT="--install_base \"/home/giovanni/perl5\""; export PERL_MB_OPT;
#PERL_MM_OPT="INSTALL_BASE=/home/giovanni/perl5"; export PERL_MM_OPT;
