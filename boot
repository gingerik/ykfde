#! /bin/sh

PREREQ=""

prereqs() {
	echo "$PREREQ"
}

case $1 in
# get pre-requisites
prereqs)
	prereqs
	exit 0
	;;
esac

if [ -s /etc/yubikey-challenge ]; then
	sed -i 's|$|,keyscript=/sbin/ykfde-keyscript|' /conf/conf.d/cryptroot
fi

exit 0
