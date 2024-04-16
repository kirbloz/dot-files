#!/bin/bash

process="flameshot"
if ! pregp -f "$process"; then
	exec flameshot gui
fi
