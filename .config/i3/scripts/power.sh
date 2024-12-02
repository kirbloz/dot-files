#! /bin/sh

chosen=$(printf "󰍃\n󰒲\n󰜉\n" | rofi -dmenu -i -theme-str '@import "~/.config/rofi/powermenu.rasi"')

case "$chosen" in
	"󰍃") i3-msg exit ;;
	"󰒲") bash ~/.config/i3/scripts/suspend.sh ;;
		# i3lock -i "/home/giovanni/Images/Lockscreen/lockscreen.png" && systemctl suspend ;;
	"󰜉") systemctl reboot ;;
	"") systemctl poweroff ;;
	*) exit 1 ;;
esac
