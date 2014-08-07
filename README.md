
# ykfde - yubikey-based full disk encryption

## Quick start

Install the package

```bash
uuidgen > /boot/yubikey-challenge
key=$(ykchalresp $(cat /boot/yubikey-challenge)) 
cryptsetup luksAddKey /dev/sda2 "$key"
```

On bootup, you will be asked to insert a Yubikey (2.2 or newer) which
will then provide the response. If you do not want to use a Yubikey,
press enter and then enter a normal passphrase during bootup.

## Limitations/bugs

* Uses the default ykchalresp settings, meaning no support for slot 2;
* Does not update the challenge after each boot.
