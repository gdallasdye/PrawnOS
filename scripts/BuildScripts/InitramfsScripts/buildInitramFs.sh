#!/bin/bash

set -x
set -e

#Build initramfs image


# This file is part of PrawnOS (https://www.prawnos.com)
# Copyright (c) 2018 Hal Emmerich <hal@halemmerich.com>

# PrawnOS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2
# as published by the Free Software Foundation.

# PrawnOS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with PrawnOS.  If not, see <https://www.gnu.org/licenses/>.


if [ -z "$1" ]
then
    echo "No base file system image supplied"
    exit 1
fi
if [ -z "$2" ]
then
    echo "No initramfs resources dir supplied"
    exit 1
fi
if [ -z "$3" ]
then
    echo "No output location supplied"
    exit 1
fi
BASE=$1
RESOURCES=$2
OUT_DIR=$3
TARGET=$4



ARCH_ARMHF=armhf
ARCH_ARM64=arm64

outmnt=$(mktemp -d -p "$(pwd)")
outdev=$(losetup -f)

if [ ! -f $BASE ]
then
    echo "No base filesystem, run 'make filesystem' first"
    exit 1
fi

#A hacky way to ensure the loops are properly unmounted and the temp files are properly deleted.
#Without this, a reboot is sometimes required to properly clean the loop devices and ensure a clean build 
cleanup() {
    set +e

    umount -l $outmnt > /dev/null 2>&1
    rmdir $outmnt > /dev/null 2>&1
    losetup -d $outdev > /dev/null 2>&1

    set +e

    umount -l $outmnt > /dev/null 2>&1
    rmdir $outmnt > /dev/null 2>&1
    losetup -d $outdev > /dev/null 2>&1
}

function chroot_get_libs
{
    set +e
    set -x
    [ $# -lt 2 ] && return

    dest=$1
    shift
    for i in "$@"
    do
        # Get an absolute path for the file
        [ "${i:0:1}" == "/" ] || i=$(which $i)
        # Skip files that already exist at target.
        [ -f "$dest/$i" ] && continue
        if [ -e "$i" ]
        then
            # Create destination path
            d=`echo "$i" | grep -o '.*/'` &&
                mkdir -p "$dest/$d" &&
                # Copy file
                cat "$i" > "$dest/$i" &&
                chmod +x "$dest/$i"
        else
            echo "Not found: $i"
        fi
        # Recursively copy shared libraries' shared libraries.
        chroot_get_libs "$dest" $(ldd "$i" | egrep -o '/.* ')
    done
}

trap cleanup INT TERM EXIT

[ ! -d build ] && mkdir build

losetup -P $outdev $BASE
#mount the root filesystem
mount -o noatime ${outdev}p2 $outmnt




#make a skeleton filesystem
initramfs_src=$outmnt/InstallResources/initramfs_src
rm -rf $initramfs_src*
mkdir -p $initramfs_src
mkdir $initramfs_src/bin
mkdir $initramfs_src/dev
mkdir $initramfs_src/etc
#mkdir $initramfs_src/etc/selinux
#mkdir $initramfs_src/etc/selinux/default
#mkdir $initramfs_src/etc/selinux/default/policy
#mkdir $initramfs_src/etc/selinux/targeted
#mkdir $initramfs_src/etc/selinux/targeted/policy
mkdir $initramfs_src/newroot
mkdir $initramfs_src/boot
mkdir $initramfs_src/proc
mkdir $initramfs_src/sys
mkdir $initramfs_src/sbin
mkdir $initramfs_src/run
mkdir $initramfs_src/run/cryptsetup
mkdir $initramfs_src/lib

mknod $initramfs_src/dev/console c 5 1
#mknod $initramfs_src/dev/fb0 c 29 0
#mknod $initramfs_src/dev/fb1 c 29 32
#mknod $initramfs_src/dev/fb2 c 29 64
#mknod $initramfs_src/dev/fb3 c 29 96
#mknod $initramfs_src/dev/fb4 c 29 128
#mknod $initramfs_src/dev/fb5 c 29 160
#mknod $initramfs_src/dev/fb6 c 29 192
#mknod $initramfs_src/dev/fb7 c 29 224
mknod $initramfs_src/dev/null c 1 3
mknod $initramfs_src/dev/tty c 5 0
mknod $initramfs_src/dev/urandom c 1 9
mknod $initramfs_src/dev/random c 1 8
mknod $initramfs_src/dev/zero c 1 5


#install the few tools we need, and the supporting libs
initramfs_binaries='/bin/busybox /sbin/cryptsetup /sbin/blkid'

#do so **automatigically**
export -f chroot_get_libs
export initramfs_binaries

chroot $outmnt /bin/bash -c "chroot_get_libs /InstallResources/initramfs_src $initramfs_binaries"

#have to add libgcc manually since ldd doesn't see it as a requirement :/
armhf_libs=arm-linux-gnueabihf
arm64_libs=aarch64-linux-gnu
if [ "$TARGET" == "$ARCH_ARMHF" ]; then
    LIBS_DIR=$armhf_libs
elif [ "$TARGET" == "$ARCH_ARM64" ]; then
    LIBS_DIR=$arm64_libs
else
    echo "no valid target arch specified"
    exit 1
fi
cp $outmnt/lib/$LIBS_DIR/libgcc_s.so.1 $initramfs_src/lib/$LIBS_DIR/

#add the init script
cp $RESOURCES/initramfs-init $initramfs_src/init
chmod +x $initramfs_src/init
cp $initramfs_src/init $initramfs_src/sbin/init

#add selinux targeted policy, so that the splashscreen may run
#TODO: selinux is normally set to off, on or permissive. Default mode for selinux is default
#Normally on Debian, one has the option to uninstall apparmor then enable selinux
#So what makes what complain about the targeted policy being missing
#link from targeted policy to default policy, in lieu of duplicating
#cp $RESOURCES/policy.31 $initramfs_src/etc/selinux/targeted/policy/policy.31
#cp $initramfs_src/etc/selinux/targeted/policy/policy.31 $initramfs_src/etc/selinux/default/policy/policy.31

#compress and install
rm -rf $outmnt/boot/PrawnOS-initramfs.cpio
cd $initramfs_src
ln -s busybox bin/cat
ln -s busybox bin/mount
ln -s busybox bin/sh
ln -s busybox bin/switch_root
ln -s busybox bin/umount

# store for kernel building. gzip is not needed becase kernel + initramfs are gzipped together
find . -print0 | cpio --null --create --verbose --format=newc > $OUT_DIR/PrawnOS-initramfs.cpio
