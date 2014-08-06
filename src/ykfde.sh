#!/bin/sh

# set the defaults
YKOPTS="-2"
LUKS_DEVICE="/dev/sda2"
LUKS_SLOT="7"
CHALLENGE_FILE="/boot/yubikey-challenge"
ERROR_LOG="/var/log/ykfde"


# read defaults..
if [ -e /etc/default/ykfde ]; then
    . /etc/default/ykfde

    if [ "${LUKS_SLOT}" = "multi" ]; then
        type ykinfo > /dev/null;
        if [ $? -ne 0 ]; then
            log_error "Multiple Yubikey support requires yubikey-personalization >= 1.8."
            echo "ykinfo: not found"
            exit 1
        fi
        echo -n "LUKS_SLOT is set to 'multi': "
        . /etc/ykfde.conf
        serial="$(ykinfo -s | awk '{print $NF}')"
        for i in $(seq 0 7); do
            if [ "${LUKS_SLOT[${i}]}" == "${serial}" ]; then
                LUKS_SLOT=${i}
                echo "Using slot ${i}"
            fi
        done
    fi
    if [ "${LUKS_SLOT}" = "multi" ]; then
        echo "No matching Yubikey found."
        exit 2
    fi
fi


log_error () {
    echo "$1" >> ${ERROR_LOG}
}

chalresp () {
    key="$(ykchalresp ${YKOPTS} $1)"

    if [ $? -ne 0 ]; then
        mv ${CHALLENGE_FILE}.old ${CHALLENGE_FILE} 2>/dev/null
        rm -f ${CHALLENGE_FILE}.new
        log_error "Challenge-response failed."
        echo "Failed"
        exit 1
    fi

    echo "${key}"
}



get_new_challenge () {
    if [ -z ${CHALLENGE} ]; then
        export CHALLENGE="$(base64 < /dev/urandom | head -c 64)"
        echo -n "${CHALLENGE}" > ${CHALLENGE_FILE}.new
        chmod 400 ${CHALLENGE_FILE}.new
    fi
}

get_old_challenge () {
    if [ -z ${OLD_CHALLENGE} ]; then
        export OLD_CHALLENGE="$(cat ${CHALLENGE_FILE})"
        mv ${CHALLENGE_FILE} ${CHALLENGE_FILE}.old
    fi
}

add_new_key () {

    key=$(chalresp ${CHALLENGE})

    response=$(cryptsetup luksAddKey \
            --key-slot ${LUKS_SLOT} ${LUKS_DEVICE} ${key} 2>&1)

    if [ $? -ne 0 ]; then
        log_error "Failed adding LUKS key to cryptsetup."
        log_error "${response}"
        echo "Failed"
        exit 1
    fi

    mv ${CHALLENGE_FILE}.new ${CHALLENGE_FILE}
}

update_key () {

    oldKey=$(chalresp ${OLD_CHALLENGE})
    newKey=$(chalresp ${CHALLENGE})

    response=$(cryptsetup luksChangeKey \
            --key-slot ${LUKS_SLOT} ${LUKS_DEVICE} \
            --key-file ${oldKey} ${newKey} 2>&1)

    if [ $? -ne 0 ]; then
        mv ${CHALLENGE_FILE}.old ${CHALLENGE_FILE}
        log_error "Failed changing LUKS key in cryptsetup."
        log_error "${response}"
        echo "Failed"
        exit 1
    fi

    mv ${CHALLENGE_FILE}.new ${CHALLENGE_FILE}
    rm -f ${CHALLENGE_FILE}.old

}

print_help () {

    echo "Usage: $0 (new|update|start|stop)"

}

case $1 in
    new)
        echo -n "Getting new key... "
        get_new_challenge && echo "OK"
        echo -n "Adding new key... "
        add_new_key && echo "OK"
        /usr/sbin/update-initramfs -u -k "$(uname -r)"

    ;;
    update|start)
        echo -n "Getting keys... "
        get_new_challenge && get_old_challenge && echo 'OK'
        echo -n "Changing key... "
        update_key && echo 'OK'
        /usr/sbin/update-initramfs -u -k "$(uname -r)"
    ;;
    stop)
        echo "Finished."
    ;;
    *)
        print_help
    ;;
esac


