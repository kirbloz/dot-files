#! /bin/sh

chosen=$(printf "Log Out\nSuspend\nRestart\nPower OFF" | rofi -dmenu -i -theme-str '@import "~/.config/rofi/powermenu.rasi"')

case "$chosen" in
	"Log Out") i3-msg exit ;;
	"Suspend") bash ~/.config/i3/scripts/suspend.sh ;;
		# i3lock -i "/home/giovanni/Images/Lockscreen/lockscreen.png" && systemctl suspend ;;
	"Restart") systemctl reboot ;;
	"Power OFF") systemctl poweroff ;;
	*) exit 1 ;;
esac
