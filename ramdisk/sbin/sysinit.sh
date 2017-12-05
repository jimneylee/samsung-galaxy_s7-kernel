#!/sbin/ash

# run init.d scripts
if [ -d "/system/etc/init.d" ]; then
    export PATH=/sbin:/system/xbin:/system/bin
    logwrapper busybox find /system/etc/init.d -type f -exec busybox ash "{}" \;
fi
