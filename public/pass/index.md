# Managing Password using Pass



# A Minimalist’s Guide to **pass**— the Unix Password Manager

*Safely wrangle your secrets from the command-line using GPG encryption and a few intuitive commands.*

---

## 1. Why *pass*?

* **Single-purpose & transparent** – every secret is just a GPG-encrypted file in `~/.password-store/`.
* **Leverages tools you already trust** – GnuPG for encryption and standard Unix commands for everything else (grep, git, find, etc.).
* **Portable & scriptable** – works the same on any POSIX shell and is easy to automate.

> **Prerequisites**
>
> * GnuPG ≥ 2.2
> * `pass` package (available in most distro repos: `pacman -S pass`, `apt install pass`, etc.)
> * A clipboard utility (`xclip`, `xsel`, `wl-clipboard`, or `pbcopy` on macOS) if you want the **copy-to-clipboard** feature.

---

## 2. Generate your first GPG key

```bash
gpg --full-generate-key
```

1. **Key Type** – pick the default **RSA & RSA** (or *ECC* if you prefer).
2. **Key Size** – 3072 or 4096 bits (stronger ⇒ larger).
3. **Expiration** – choose a sensible period (e.g., 2 years) so compromised keys self-retire.
4. **Identity** – enter the name + e-mail that will label this key.
5. **Passphrase** – a *strong* one! You’ll type this each time GPG needs your key (or unlock once per session via a GPG agent).

---

## 3. Find your key ID

```bash
gpg --list-secret-key --keyid-format LONG
```

Look for the line that starts with `sec`:

```
sec   rsa3072/AB12CD34EF56GH78 2025-05-17 [SC]  
```

`AB12CD34EF56GH78` (16 hexadecimal characters after the slash) is **your key ID** – copy it; we’ll use it to initialise *pass*.

---

## 4. Initialise *pass*

```bash
pass init AB12CD34EF56GH78
```

What happens?

* `pass` creates `~/.password-store/`
* Every file placed there will be encrypted **for the listed key(s)**.
* A `.gpg-id` file records which keys to use so you can share the store with additional people later.

*(If you ever rotate keys, run `pass init --path . newKEYID` to re-encrypt subsets of the store.)*

---

## 5. Add your first secret

```bash
pass insert twitter.com
```

* `pass` opens your `$EDITOR` (= `vi`, `nano`, etc.).
* Type your password on the **first line**; anything after that is free-form notes (e.g., username, 2FA scratch codes).
* Save & quit – you’ll be prompted for your GPG passphrase and the file `twitter.com.gpg` is created inside the store.

Directory layout after one entry:

```text
~/.password-store/
├── .gpg-id
└── twitter.com.gpg
```

*(Feel free to nest categories like `Business/github.com`, they become sub-directories.)*

---

## 6. Display or decrypt secrets

Plain display (prints to STDOUT):

```bash
pass twitter.com          # same as `pass twitter`
```

One-off manual decryption (rarely needed, but shows nothing up *pass*’s sleeve):

```bash
gpg -d ~/.password-store/facebook.com.gpg
```

---

## 7. Copy to clipboard (auto-clear!)

```bash
pass -c git_token
```

* The password is pushed to your clipboard.
* After **45 seconds** (configurable via `PASSWORD_STORE_CLIP_TIME`), `pass` industriously scrubs it.

---

## 8. Remove an entry

```bash
pass rm Business/cheese-whiz-factory
```

Flags worth knowing:

* `-r` → *recursive* (delete directories).
* `-f` → *force* (skip confirmation).

Deleted files go to your desktop trash **only** if your shell supports it; otherwise they’re gone forever (but still recoverable via `git`, see below).

---

## 9. Pro tips & hygiene

| Task                                       | Command / Tip                                                                                                                                                             |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Version control** your store             | `cd ~/.password-store && git init && git add . && git commit -m "First secret"`<br>With Git you get effortless history and the ability to sync between machines over SSH. |
| Use multiple recipients (e.g., team store) | `pass init KEYID1 KEYID2 ...` – future inserts are encrypted for *all* recipients.                                                                                        |
| Rename or move a secret                    | `pass mv oldname newname` – keeps history intact.                                                                                                                         |
| Bulk import existing passwords             | `pass import pass-dump.txt` or script with `pass insert -m <name>`.                                                                                                       |
| Search                                     | `pass grep <pattern>` – greps filenames **and** decrypted contents.                                                                                                       |
| Shell tab-completion                       | Enable the bundled `pass.bash-completion` or `pass.fish-completion` for lightning-fast navigation.                                                                        |
| GUI helpers                                | `qtpass`, `browserpass`, `passff` let your browser/mobile talk to the same store.                                                                                         |

---

## 10. Backing up & restoring

Because the store is plain GPG files:

```bash
tar czf pass-backup-$(date +%F).tar.gz ~/.password-store
```

To restore:

```bash
tar xzf pass-backup-2025-05-17.tar.gz -C ~/
pass git checkout .
```

*(If you kept the Git repo you can just `git pull` from your remote.)*

---

## 11. Revoking / rotating your key

1. Generate & publish a **revocation certificate** right after key creation:

   ```bash
   gpg --output ~/revocation.asc --gen-revoke AB12CD34EF56GH78
   ```
2. If the key is ever compromised, import that file (`gpg --import revocation.asc`) and re-encrypt the store with a new key:

   ```bash
   gpg --full-generate-key          # new key
   pass init NEWKEYID               # re-encrypt everything
   ```

---

## 12. Final thoughts

*pass* embraces the Unix philosophy: **keep it simple, text-based, and composable**. Once you have your GPG key and a handful of commands memorised, your passwords live safely in a Git-versioned, human-readable directory—no proprietary clouds, no black-box databases.

Happy hacking, and may your secrets stay secret!

