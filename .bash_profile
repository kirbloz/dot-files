#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# SET ENV VARS

export EDITOR="vim"
export PATH="${PATH}:/home/giovanni/Tools/idea-IU-241.17890.1/bin"

# UPDATE DB
# only executable from sudo... mh.. need a work around
# pacman -Syu
# found it! an alias for poweroff and reboot handles it :thumbs_up:




# start Xserver
# exec startx





# set max temp at 97C
sudo ryzenadj --tctl-temp=97
