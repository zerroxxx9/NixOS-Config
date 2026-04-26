# ?? NixOS Multi-Host Configuration

This repository contains my modular NixOS system configuration, powered by [Nix Flakes](https://nixos.wiki/wiki/Flakes) and [Home Manager](https://nix-community.github.io/home-manager/).

## ? Features

- ?? Flake-based for reproducibility
- ?? Modular configuration per host
- ?? Includes Home Manager for user-level setup
- ?? Centralized `variables.nix` for system flags and module toggles
- ?? agenix-ready secret workflow with host SSH keys and optional YubiKey admin decrypt

---

## ??? Getting Started

### 1. Clone into `.dotfiles`

```bash
git clone https://github.com/zerroxxx9/NixOS-dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### 2. Use an existing host

Edit:

```nix
./hosts/{work,wsl,homelab}/variables.nix
```

Then run:

```bash
sudo nixos-rebuild switch --flake ~/.dotfiles#work
```

For later rebuilds:

```bash
rebuild
```

or
```bash
switch
```

> `rebuild` and `switch` is an alias for `nixos-rebuild` with predefined arguments.

### 3. Secrets with agenix

The encrypted secret workflow lives in [./secrets/README.md](./secrets/README.md).
The short version:

- commit encrypted `*.age` files
- commit public recipients under `./secrets/recipients/`
- keep private SSH keys and YubiKey identity files outside the repo

---

## ? Adding a New Host

1. Create a new folder in `./hosts/`, e.g. `home-pc`
2. Add these files:
    - `configuration.nix`
    - `default.nix`
    - `hardware-configuration.nix`
    - `variables.nix`

3. Your `variables.nix` should follow this structure:

```nix
let default = import ../../variables/defaultVariables.nix; in
default // {
  username = "zerrox";
  host = "default";
  system = "x86_64-linux";
  stateVersion = "25.11";
  modules = default.modules // {
    software = default.modules.software // {
      docker = true;
      git = true;
      tailscale = false;
    };
    security = default.modules.security // {
      yubikey = true;
      agenix = true;
    };
  };
  git = default.git // {
    extraConfig = default.git.extraConfig // {
      credential-helper = null;
    };
  };
}
```

4. Finally, register the host in your `flake.nix`:

```nix
nixosConfigurations = {
  home-pc = mkNixosConfiguration {
    modules = [ ./hosts/home-pc ];
    hostVariables = import ./hosts/home-pc/variables.nix;
  };
};
```

---

## ?? Troubleshooting & Known Issues

### ? `attribute 'xyz' missing`

Ensure that your `variables.nix` file contains all required attributes. Use a central default like:

```nix
let default = import ../../variables/defaultVariables.nix; in
default // { ... }
```

This ensures every module gets all expected keys.

### ?? Module flags not working

Make sure you?re not accidentally shadowing or omitting expected fields:

- Use `default.modules // { ... }` instead of `{}` when overriding
- Use `lib.attrByPath` or `lib.getAttrFromPath` for optional flags

---

### ?? Flake not updating correctly

Run:

```bash
nix flake update
rebuild switch --flake .#your-host
```

If you're using `nix-direnv`, reload the shell with `direnv reload`.

---
