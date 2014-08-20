
# ykfde - yubikey-based full disk encryption

## Quick start

Install the package

```bash
service ykfde restart
```

On bootup, you will be asked to insert a Yubikey (2.2 or newer) which
will then provide the response. If you do not want to use a Yubikey,
press enter and then enter a normal passphrase during bootup.

## Limitations/bugs

* You **must** always use the same Yubikey.
