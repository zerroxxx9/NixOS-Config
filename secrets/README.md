# Secrets with agenix

This repository is set up for the following model:

- target machines decrypt with their own SSH host keys
- you can add a YubiKey-backed `age` recipient as an admin recipient for editing and rekeying
- only encrypted `*.age` files and public recipient files are committed

## Files in this directory

- `secrets.nix`
  Defines which recipients can decrypt each encrypted secret.
- `recipients/`
  Contains public recipients that are safe to commit.
- `*.age`
  Encrypted secret files that are safe to commit.

## 1. Add recipients

Add the committed recipient files expected by `secrets.nix`:

- `recipients/zerrox-yubikey.age.pub`
- `recipients/work-ssh-host-ed25519.pub`
- `recipients/homelab-ssh-host-ed25519.pub`

Optional fallback admin recipient:

- `recipients/zerrox-admin-ssh-ed25519.pub`

Useful commands:

```bash
cat /etc/ssh/ssh_host_ed25519_key.pub
ssh-keyscan -t ed25519 your-hostname
```

## 2. Create a YubiKey age identity

Keep the identity file outside the repository, for example:

```bash
mkdir -p ~/.config/age/identities
age-plugin-yubikey --generate --name dotfiles > ~/.config/age/identities/yubikey.txt
age-plugin-yubikey --list > secrets/recipients/zerrox-yubikey.age.pub
```

If you work from WSL, make sure your YubiKey is actually reachable there, for example via USB passthrough or a Windows-side setup that exposes the token to WSL.

## 3. Create or edit encrypted secrets

From the repository root:

```bash
RULES=secrets/secrets.nix agenix -e secrets/tailscale-authkey.age -i ~/.config/age/identities/yubikey.txt
RULES=secrets/secrets.nix agenix -e secrets/wifi-passwords.age -i ~/.config/age/identities/yubikey.txt
RULES=secrets/secrets.nix agenix -e secrets/copilot-api-key.age -i ~/.config/age/identities/yubikey.txt
RULES=secrets/secrets.nix agenix -e secrets/brave-bookmarks.age -i ~/.config/age/identities/yubikey.txt
```

## 4. What not to commit

Do not commit:

- plaintext secret files
- private SSH keys
- `~/.config/age/identities/yubikey.txt`
