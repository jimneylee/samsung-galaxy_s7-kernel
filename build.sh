#!/bin/bash
##
##  This script is supposed to run in AArch64 chroot linux environmnet
##

####################################################################################################
##
##	Configurable parameters
##

# Number of parallel jobs of make
MAKE_JOBS="7"

# Priority of make processes
NICE_LEVEL="7"

# Defconfig for building kernel
KERNEL_DEFCONFIG="exynos8890-herolte-basic_defconfig"

####################################################################################################
##
##	Static parameters (do not touch)
##

# Set locale to 'C'
export LANG="C"

# Set Time Zone to 'UTC'
export TZ="UTC"

# Target architecture
export ARCH="arm64"

# Base directory of kernel sources (for example /usr/src/linux)
KERNEL_SOURCES_DIR=$(realpath "$(dirname '${0}')")

# Directory with Android's ramdisk sources (for example /usr/src/linux/ramdisk)
RAMDISK_SOURCES_DIR="${KERNEL_SOURCES_DIR}/ramdisk"

# Directory with DTS files
DTS_DIR="${KERNEL_SOURCES_DIR}/arch/arm64/boot/dts"

# Directory with DTB files
DTB_DIR="${KERNEL_SOURCES_DIR}/arch/arm64/boot/dtb"

# DTS Files
DTS_FILES="exynos8890-herolte_eur_open_00 \
exynos8890-herolte_eur_open_01 \
exynos8890-herolte_eur_open_02 \
exynos8890-herolte_eur_open_03 \
exynos8890-herolte_eur_open_04 \
exynos8890-herolte_eur_open_08 \
exynos8890-herolte_eur_open_09"

# Path to built images
KERNEL_IMAGE="${KERNEL_SOURCES_DIR}/arch/arm64/boot/Image"
DEVICE_TREE_IMAGE="${KERNEL_SOURCES_DIR}/arch/arm64/boot/dtb.img"
RAMDISK_IMAGE="${KERNEL_SOURCES_DIR}/arch/arm64/boot/ramdisk.img"
ANDROID_BOOT_IMAGE="${KERNEL_SOURCES_DIR}/android_boot.img"

# Path to build programs
DTCTOOL="${KERNEL_SOURCES_DIR}/scripts/dtc/dtc"
DTBTOOL="${KERNEL_SOURCES_DIR}/scripts/dtbTool/dtbTool"
MKBOOTFS="${KERNEL_SOURCES_DIR}/scripts/android_bootimg_tools/mkbootfs"
MKBOOTIMG="${KERNEL_SOURCES_DIR}/scripts/android_bootimg_tools/mkbootimg"

# Configs for device tree
DTB_PADDING="0"
DTB_PAGESIZE="2048"

# Configs for boot image
BOOTIMG_CONFIG_CMDLINE=""
BOOTIMG_CONFIG_BOARD="SRPOI17A000KU"
BOOTIMG_CONFIG_BASE="10000000"
BOOTIMG_CONFIG_PAGESIZE="2048"
BOOTIMG_CONFIG_KERNEL_OFFSET="00008000"
BOOTIMG_CONFIG_RAMDISK_OFFSET="01000000"
BOOTIMG_CONFIG_TAGS_OFFSET="00000100"

####################################################################################################
##
##	Lets do some checks
##

# Check ramdisk directory
if [ ! -d "${RAMDISK_SOURCES_DIR}" ]; then
    echo " [!] Ramdisk sources path is not a directory."
    exit 1
fi

# Check defconfig
if [ ! -f "${KERNEL_SOURCES_DIR}/arch/arm64/configs/${KERNEL_DEFCONFIG}" ]; then
    echo " [!] Kernel defconfig not found."
    exit 1
fi

####################################################################################################
##
##	Functions
##

#
#  Clean kernel tree
#
cleanup()
{
    local START_TIME

    echo
    echo " ===== Cleaning"

    START_TIME=$(date +%s)

    rm -f "${KERNEL_SOURCES_DIR}/scripts/dtbTool/dtbTool"
    rm -f "${KERNEL_SOURCES_DIR}/scripts/android_bootimg_tools/mkbootfs"
    rm -f "${KERNEL_SOURCES_DIR}/scripts/android_bootimg_tools/mkbootimg"
    rm -f "${KERNEL_SOURCES_DIR}/scripts/android_bootimg_tools/unpackbootimg"

    rm -rf "${DTB_DIR}"
    rm -f "${DTS_DIR}/*.dtb"

    rm -f "${DEVICE_TREE_IMAGE}"
    rm -f "${RAMDISK_IMAGE}"
    rm -f "${ANDROID_BOOT_IMAGE}"
    rm -f "${RAMDISK_SOURCES_DIR}/default.prop"

    nice -n "${NICE_LEVEL}" make distclean > /dev/null 2>&1

    echo " [*] Cleaned. (elapsed time: $(($(date +%s) - START_TIME)) seconds)"
}

#
#  Apply defconfig
#
configure_kernel()
{
    local START_TIME

    # Build dtbTool
    cd "${KERNEL_SOURCES_DIR}/scripts/dtbTool" && {
        echo " [*] Building DTB tool"
        echo
        make clean
        make -j ${MAKE_JOBS}
        echo
        cd "${KERNEL_SOURCES_DIR}"
    } || {
        echo " [!] Cannot find source code for DTB tool."
        exit 1
    }

    # Build boot.img tools
    cd "${KERNEL_SOURCES_DIR}/scripts/android_bootimg_tools" && {
        echo " [*] Building boot.img tools"
        echo
        make clean
        make -j ${MAKE_JOBS}
        echo
        cd "${KERNEL_SOURCES_DIR}"
    } || {
        echo " [!] Cannot find source code for boot.img tools."
        exit 1
    }

    echo " ===== Configuring kernel"

    START_TIME=$(date +%s)

    if nice -n "${NICE_LEVEL}" make -j "${MAKE_JOBS}" "${KERNEL_DEFCONFIG}"; then
        echo
        echo " [*] Kernel successfully configured with '${KERNEL_DEFCONFIG}'. (elapsed time: $(($(date +%s) - START_TIME)) seconds)"
    else
        echo
        echo " [!] Failed to configure kernel. (elapsed time: $(($(date +%s) - START_TIME)) seconds)"
        echo

        exit 1
    fi
}

#
#  Compile kernel and device tree
#
compile_kernel()
{
    local START_TIME

    if [ ! -e "${KERNEL_SOURCES_DIR}/.config" ]; then
        echo
        echo " [!] Kernel is not configured."
        echo

        exit 1
    fi

	##
	##	Bulding kernel
	##

    echo
    echo " ===== Compiling kernel"
    echo

    START_TIME=$(date +%s)

    if nice -n "${NICE_LEVEL}" make -j "${MAKE_JOBS}"; then
        echo
        echo " [*] Kernel successfully compiled. (elapsed time: $(($(date +%s) - START_TIME)) seconds)"
    else
        echo
        echo " [!] Failed to compile kernel. (elapsed time: $(($(date +%s) - START_TIME)) seconds)"
        echo

        exit 1
    fi

	##
	##	Bulding device tree
	##

    echo
    echo " ===== Generating device tree"

	# Error if DTB_DIR is not a directory
    if [ -e "${DTB_DIR}" ]; then
        if [ ! -d "${DTB_DIR}" ]; then
            echo " [!] '${DTB_DIR}' is not a directory."
            echo

            exit 1
        fi
    fi

	# Clean DTB_DIR if it exists
    [ -d "${DTB_DIR}" ] && rm -f "${DTB_DIR}/*"

	# Create DTB_DIR if it not exist
    [ ! -e "${DTB_DIR}" ] && mkdir -p "${DTB_DIR}"

    START_TIME=$(date +%s)

    for dts in ${DTS_FILES}; do
        cpp -nostdinc -undef -x assembler-with-cpp -I "${KERNEL_SOURCES_DIR}/include" \
            "${DTS_DIR}/${dts}.dts" -o "${DTB_DIR}/${dts}.dts" > /dev/null 2>&1

        "${DTCTOOL}" -p "${DTB_PADDING}" -i "${DTS_DIR}" -O dtb -o "${DTB_DIR}/${dts}.dtb" \
            "${DTB_DIR}/${dts}.dts" > /dev/null 2>&1
    done

    if "${DTBTOOL}" -o "${DEVICE_TREE_IMAGE}" -d "${DTB_DIR}/" -s "${DTB_PAGESIZE}" > /dev/null 2>&1; then
        echo " [*] Device tree successfully generated. (elapsed time: $(($(date +%s) - START_TIME)) seconds)"
    else
        echo " [*] Failed to generate device tree. (elapsed time: $(($(date +%s) - START_TIME)) seconds)"
        echo

        exit 1
    fi
}

#
#  Create boot.img
#
create_bootimg()
{
    local START_TIME

    if [ ! -e "${KERNEL_IMAGE}" ] || [ ! -e "${DEVICE_TREE_IMAGE}" ]; then
        echo
        echo " [!] Kernel is not compiled."
        echo

        exit 1
    fi

    echo
    echo " ===== Generating bootable image"

    [ -e "${RAMDISK_IMAGE}" ] && rm -f "${RAMDISK_IMAGE}"

    START_TIME=$(date +%s)

    cp "${RAMDISK_SOURCES_DIR}/default.prop.init" "${RAMDISK_SOURCES_DIR}/default.prop"

    echo "ro.bootimage.build.date=$(date)" >> "${RAMDISK_SOURCES_DIR}/default.prop"
    echo "ro.bootimage.build.date.utc=$(date +%s)" >> "${RAMDISK_SOURCES_DIR}/default.prop"

    if "${MKBOOTFS}" "${RAMDISK_SOURCES_DIR}" | xz -9e --check=crc32 > "$RAMDISK_IMAGE"; then
        echo " [*] Ramdisk successfully created. (elapsed time: $(($(date +%s) - START_TIME)) seconds)"
    else
        echo " [!] Failed to create ramdisk. (elapsed time: $(($(date +%s) - START_TIME)) seconds)"
        echo

        exit 1
    fi

    START_TIME=$(date +%s)

    if "${MKBOOTIMG}" --kernel "${KERNEL_IMAGE}"                    \
              --ramdisk "${RAMDISK_IMAGE}"                          \
              --cmdline "${BOOTIMG_CONFIG_CMDLINE}"                 \
              --board "${BOOTIMG_CONFIG_BOARD}"                     \
              --base "${BOOTIMG_CONFIG_BASE}"                       \
              --pagesize "${BOOTIMG_CONFIG_PAGESIZE}"               \
              --kernel_offset "${BOOTIMG_CONFIG_KERNEL_OFFSET}"     \
              --ramdisk_offset "${BOOTIMG_CONFIG_RAMDISK_OFFSET}"   \
              --tags_offset "${BOOTIMG_CONFIG_TAGS_OFFSET}"         \
              --dt "${DEVICE_TREE_IMAGE}"                           \
              -o "${ANDROID_BOOT_IMAGE}"; then

            if echo -n "SEANDROIDENFORCE" >> "${ANDROID_BOOT_IMAGE}"; then
                echo " [*] Boot image created. (elapsed time: $(($(date +%s) - START_TIME)) seconds)"
            else
                echo " [!] Failed to create a boot image. (elapsed time: $(($(date +%s) - START_TIME)) seconds)"
                echo
                exit 1
            fi
    else
        echo " [!] Failed to create a boot image. (elapsed time: $(($(date +%s) - START_TIME)) seconds)"
        echo
        exit 1
    fi
}

####################################################################################################
##
##	Menu
##

echo
echo " Choose option from: "
echo "   1) Build fresh kernel"
echo "   2) Recompile kernel"
echo "   3) Rebuild boot.img"
echo "   4) Clean"
echo
echo -n " Choice (1-4): "

read -r CHOICE

case "${CHOICE}" in
    1)
        cleanup
        configure_kernel
        compile_kernel
        create_bootimg
        ;;

    2)
        compile_kernel
        create_bootimg
        ;;

    3)
        create_bootimg
        ;;

    4)
        cleanup
        ;;

    *)
        echo
        echo " [!] Invalid choice."
        echo
        exit 1
        ;;
esac

echo
echo " ##### Done"
echo

exit 0
