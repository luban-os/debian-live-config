#!/bin/bash -e

MOUNTPOINT="rootfs"
TARGET_ROOTFS_DIR="live-rootfs"
RELEASE_VERSION="0.0.0"


#------------live-build-------------
# make install_buildenv && make

if [ ! -e binary/live/$TARGET_ROOTFS_DIR ]; then
	mkdir -p binary/live/$TARGET_ROOTFS_DIR
fi

#------------prepare rootfs image-------------
if [ ! -e binary/live/$MOUNTPOINT ]; then
	mkdir -p binary/live/$MOUNTPOINT
fi

mount binary/live/filesystem.squashfs binary/live/$MOUNTPOINT -t squashfs -o loop

echo "1.copying live os filesystem...."
cp -drfp binary/live/$MOUNTPOINT/* binary/live/$TARGET_ROOTFS_DIR

umount binary/live/${MOUNTPOINT}

#--------------chroot---------------------------

cd binary/live/

echo "2.install/remove/adjust debian"

finish() {
	sudo umount $TARGET_ROOTFS_DIR/dev
	exit -1
}
trap finish ERR

mv $TARGET_ROOTFS_DIR/etc/resolv.conf $TARGET_ROOTFS_DIR/etc/resolv.conf.bck
sudo cp -f /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/

sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

cat << EOF | sudo chroot $TARGET_ROOTFS_DIR


#-----------------Install------------------
apt-get update
### legancy mode
apt-get install -y grub-pc grub-pc-bin
### efi mode
apt-get install -y grub-efi grub-efi-amd64 grub-efi-amd64-bin grub-efi-amd64-signed

# Create User
#useradd -G sudo,dialout,fax,cdrom,floppy,tape,audio,dip,video,plugdev,scanner,netdev -m -s /bin/bash linaro
#passwd linaro <<IEOF
#123456
#123456
#IEOF

#passwd root <<IEOF
#123456
#123456
#IEOF

#Timezone
#echo "Asia/Shanghai" > /etc/timezone
#default localtime -> /usr/share/zoneinfo/Etc/UTC
#ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

EOF

mv $TARGET_ROOTFS_DIR/etc/resolv.conf.bck $TARGET_ROOTFS_DIR/etc/resolv.conf

sudo umount $TARGET_ROOTFS_DIR/dev

if [ -e advlinux-${RELEASE_VERSION}.img ]; then
	rm -rf advlinux-${RELEASE_VERSION}.img
fi

mksquashfs ./${TARGET_ROOTFS_DIR} advlinux-${RELEASE_VERSION}.img




