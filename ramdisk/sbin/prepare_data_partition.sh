#!/sbin/ash
##
##  Run Device Guardian if data partition is LUKS encrypted
##

export PATH=/sbin
export LD_LIBRARY_PATH=/lib64

DATA_BLOCK="/dev/block/platform/155a0000.ufs/by-name/USERDATA"
DATA_DECRYPTED_BLOCK_NAME="userdata_luks"

if cryptsetup isLuks "${DATA_BLOCK}" && [ ! -e "/dev/mapper/${DATA_DECRYPTED_BLOCK_NAME}" ]; then
    ## Start battery saver (needed for shutting down device if
    ## it running device guardian for more than 5 minutes)
    battery_saver 300 > /dev/null 2>&1 &

    ## Start gui application so we can receive password from keyboard
    ## and put it to cryptsetup
    dev_guardian > /dev/null 2>&1
else
    resetprop "ro.ramdisk.devdata.encrypted" "0"
fi
