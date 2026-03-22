#
#	Copyright (C) 2023-2024 OrangeFox Recovery Project
#	This file is part of the OrangeFox Recovery Project.
#
#	OrangeFox is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	(at your option) any later version.
#
#	OrangeFox is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	The GNU General Public License: see <http://www.gnu.org/licenses/>
#

# set to 1 during the testing phase, else set to 0
debug_mode=0;

# DEBUG mode?
[ "$debug_mode" = "1" ] && set -o xtrace;

# log the messages
LOGMSG() {
  echo "I:$@" >> /tmp/recovery.log;
}

# test-phase log messages
TESTING_LOG() {
	[ "$debug_mode" = "1" ] && LOGMSG "$@";
}

# whether the installed ROM has dynamic partitions
rom_has_dynamic_partitions() {
  local BUILD_DEVICE="mido";
  local markers=""$BUILD_DEVICE"_dynamic_partitions "$BUILD_DEVICE"_dynpart xiaomi_dynamic_partitions qti_dynamic_partitions xiaomi_dynpart qti_dynpart";
  local F=/tmp/blck_tmp;
  dd if=/dev/block/by-name/system bs=256k count=1 of=$F;
  strings $F | grep dyn > "$F.txt";
  for i in $markers
  do
	TESTING_LOG "Checking for $i in $F.txt";
	if grep $i "$F.txt" > /dev/null; then
		echo "1";
		rm -f $F*;
		return;
     	fi
  done
  rm -f $F*;
  echo "0";
}

# is this a dynamic build?
is_dynamic_build() {
	local d=$(getprop "ro.boot.dynamic_partitions");
	local e=$(getprop "ro.boot.dynamic_partitions_retrofit");
	local v=$(getprop "ro.orangefox.dynamic.build");
	if  [ "$v" = "true" ] || [ "$d" = "true" -a "$e" = "true" ]; then
		echo "1";
	else
		echo "0";
	fi
}

# set r/w at the block level
set_read_write_partitions() {
  local i=$(getprop "ro.orangefox.fastbootd");
  [ "$i" = "1" ] && return; # don't run this in fastbootd mode

  i=$(getprop "ro.boot.dynamic_partitions_retrofit");
  [ "$i" != "true" ] && return; # only run on dynamic

  local Parts="system system_ext vendor product odm";
  for i in $Parts
  do
     LOGMSG "OrangeFox: setting $i to read/write";
     blockdev --setrw /dev/block/mapper/$i;
  done
}

# hardware keys, etc
sortout_keys() {
	echo battery-charging > /sys/class/leds/blue/trigger;
	echo battery-full > /sys/class/leds/green/trigger;
	echo bkl-trigger > /sys/class/leds/button-backlight/trigger;

	# Enable keys by default
	echo 5 > /sys/class/leds/button-backlight/brightness;

	echo "0" > /sys/class/leds/led:torch_1/max_brightness;
	echo "0" > /sys/class/leds/torch-light1/max_brightness;
	echo "0" > /sys/class/leds/led:flash_1/max_brightness;

	echo "0" > /proc/touchpanel/capacitive_keys_disable;
}
#
