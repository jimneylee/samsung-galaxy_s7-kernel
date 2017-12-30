#!/sbin/ash
##
##  Open LUKS device for /data
##

export PATH=/sbin
export LD_LIBRARY_PATH=/lib64

DATA_BLOCK="/dev/block/platform/155a0000.ufs/by-name/USERDATA"
DATA_DECRYPTED_BLOCK_NAME="userdata_luks"

error_occurred()
{
    echo 200 > /sys/devices/virtual/timed_output/vibrator/enable
    usleep 400000
    echo 200 > /sys/devices/virtual/timed_output/vibrator/enable
    usleep 400000
    echo 200 > /sys/devices/virtual/timed_output/vibrator/enable
    usleep 400000
}

critical_error_occurred()
{
    echo 3000 > /sys/devices/virtual/timed_output/vibrator/enable
    sleep 3
    killall -9 dev_guardian
    sync
    reboot -f
}

if [ -z "${1}" ]; then
    critical_error_occurred
fi

if /sbin/echo -n "${1}" | cryptsetup --allow-discards luksOpen "${DATA_BLOCK}" "${DATA_DECRYPTED_BLOCK_NAME}" -; then
    if [ -e "/dev/mapper/${DATA_DECRYPTED_BLOCK_NAME}" ]; then
        ## Stop battery saver
        killall -9 battery_saver

        ## Stop device guardian
        killall -9 dev_guardian
        resetprop "ro.ramdisk.devdata.encrypted" "1"
    else
        critical_error_occurred
    fi
else
    error_occurred
fi
