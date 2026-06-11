# NixOS Multi-Host Configuration

Personal NixOS dotfiles for multiple machines, built with [Nix Flakes](https://nixos.wiki/wiki/Flakes), [Home Manager](https://nix-community.github.io/home-manager/), and a small set of host-specific module flags.

The main branch of this configuration currently tracks NixOS `25.11` and Home Manager `release-25.11`.

## What is included

- Flake-based NixOS systems with shared base configuration
- Host-specific configuration under `./hosts/<host>/`
- Home Manager integration for the configured user
- Toggleable modules for console, drivers, GUI, software, security, and system settings
- `agenix` support for encrypted secrets
- Stable `nixpkgs` plus an `unstable` overlay for selected packages
- `nh` configured to use this repository as the system flake
- A minimal Raspberry Pi configuration path for `armv6l-linux`

## Hosts

Registered hosts live in `flake.nix`:

| Host | Notes |
| --- | --- |
| `work` | Main workstation profile |
| `desktop` | Desktop profile |
| `thinkpad` | Laptop profile |
| `homelab` | Headless/server-style profile |
| `wsl` | NixOS-WSL profile |
| `raspberry-pi` | Minimal Raspberry Pi profile |

Each host imports the shared configuration and customizes behavior through `hosts/<host>/variables.nix`.

## Repository layout

```text
.
|-- flake.nix
|-- configuration.nix
|-- home.nix
|-- hosts/
|   |-- desktop/
|   |-- homelab/
|   |-- raspberry-pi/
|   |-- thinkpad/
|   |-- work/
|   `-- wsl/
|-- modules/
|   |-- console/
|   |-- driver/
|   |-- gui/
|   |-- security/
|   |-- software/
|   `-- system/
|-- secrets/
`-- variables/
```

## Getting started

Clone the repository to the expected location:

```bash
git clone https://github.com/zerroxxx9/NixOS-dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

Build and switch to one of the registered hosts:

```bash
sudo nixos-rebuild switch --flake ~/.dotfiles#work
```

After the configuration is active, these aliases are available:

```bash
rebuild     # sudo nixos-rebuild switch --flake /home/<user>/.dotfiles#<host>
switchnix   # nh os switch -H <host> /home/<user>/.dotfiles
update      # nix flake update --flake /home/<user>/.dotfiles
nixfmt      # alejandra ./
```

## Updating

Update flake inputs:

```bash
nix flake update --flake ~/.dotfiles
```

Then switch the system:

```bash
sudo nixos-rebuild switch --flake ~/.dotfiles#work
```

or, once aliases are available:

```bash
update
rebuild
```

## Host variables

Defaults live in `variables/defaultVariables.nix`. Host files should import those defaults and override only the values they need.

Example:

```nix
let
  default = import ./../../variables/defaultVariables.nix;
in
  default
  // {
    host = "home-pc";
    system = "x86_64-linux";

    modules =
      default.modules
      // {
        driver =
          default.modules.driver
          // {
            amdgpu = true;
          };

        gui =
          default.modules.gui
          // {
            gnome = true;
            hyprland = false;
          };

        software =
          default.modules.software
          // {
            docker = true;
            tailscale = true;
          };

        security =
          default.modules.security
          // {
            agenix = true;
            yubikey = false;
          };
      };
  }
```

Important top-level values:

- `username`: Linux user managed by Home Manager
- `host`: flake host name and alias target
- `system`: target system architecture
- `buildSystem`: optional build platform, used by the minimal Raspberry Pi config
- `stateVersion`: NixOS/Home Manager state version
- `modules`: feature flags consumed by `configuration.nix`
- `git`: Git identity, extra config, LFS setting, and conditional includes
- `gnome`: GNOME favorites and idle delay settings

## Module flags

The shared `configuration.nix` reads feature flags with `lib.attrByPath`, so missing flags fall back to `false`. Still, host files should merge from `default.modules` to keep intent clear.

Current module groups:

- `console`: `fish`, `alacritty`
- `driver`: `amdgpu`, `nvidia`
- `gui`: `gnome`, `hyprland`
- `software`: `collabora`, `display-link`, `docker`, `couchdb`, `fail2ban`, `flatpak`, `git`, `immich`, `noisetorch`, `obsidian`, `opencloud`, `paperless-ngx`, `spicetify`, `sunshine`, `tailscale`, `vencord`, `vscode`
- `security`: `agenix`, `yubikey`
- `systemSettings`: `bootanimation`, `gaming`

## Adding a new host

1. Create a new folder under `./hosts/`, for example `./hosts/home-pc/`.
2. Add the host files:
   - `default.nix`
   - `configuration.nix`
   - `hardware-configuration.nix` when needed
   - `variables.nix`
3. Import `variables/defaultVariables.nix` in the host `variables.nix` and override only host-specific values.
4. Register the host in `flake.nix`.

Example `flake.nix` entry:

```nix
home-pc = mkNixosConfiguration {
  modules = [./hosts/home-pc];
  hostVariables = import ./hosts/home-pc/variables.nix;
};
```

For a minimal host similar to `raspberry-pi`, use `mkMinimalNixosConfiguration` instead.

## Secrets

Secrets are managed with `agenix`. See [secrets/README.md](./secrets/README.md) for the detailed workflow.

Short version:

- Commit encrypted `*.age` files.
- Commit public recipients under `./secrets/recipients/`.
- Keep private SSH keys and YubiKey identity files outside this repository.

## Formatting

Format Nix files with:

```bash
alejandra ./
```

or, once aliases are available:

```bash
nixfmt
```

## Troubleshooting

### `attribute 'xyz' missing`

Make sure the host `variables.nix` imports and merges `variables/defaultVariables.nix`:

```nix
let
  default = import ../../variables/defaultVariables.nix;
in
  default // { ... }
```

### Module flag is ignored

Check that the flag path matches the path read in `configuration.nix`. For example, `modules.software.display-link` is intentionally spelled with a hyphen.

### Flake input update did not apply

Update the lock file and rebuild the selected host:

```bash
nix flake update --flake ~/.dotfiles
sudo nixos-rebuild switch --flake ~/.dotfiles#work
```

If `nix-direnv` is in use, reload the shell:

```bash
direnv reload
```
