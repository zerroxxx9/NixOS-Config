{
  nixConfig = {
    extra-substituters = ["https://cache.numtide.com"];
    extra-trusted-public-keys = ["niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    llm-agents.url = "github:numtide/llm-agents.nix";
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager?ref=release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ilyamiro-dots = {
      url = "github:ilyamiro/nixos-configuration";
      flake = false;
    };
    qs-hyprview = {
      url = "github:dom0/qs-hyprview";
      flake = false;
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    ...
  }: let
    mkNixosConfiguration = {
      modules ? [],
      hostVariables,
    }: let
      system = hostVariables.system;
      pkgs-config = {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-unstable = import inputs.nixpkgs-unstable pkgs-config;
    in
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules =
          modules
          ++ [
            ./configuration.nix
            ./modules
            home-manager.nixosModules.home-manager
            inputs.nixvim.nixosModules.nixvim
            inputs.agenix.nixosModules.default
            {
              nixpkgs.overlays = [
                (final: prev: {
                  unstable = pkgs-unstable;
                })
              ];
            }
          ];
        specialArgs = {
          inherit hostVariables inputs system;
        };
      };
    mkMinimalNixosConfiguration = {
      modules ? [],
      hostVariables,
    }: let
      system = hostVariables.buildSystem or hostVariables.system;
    in
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules =
          modules
          ++ [
            {
              nixpkgs.buildPlatform = system;
            }
          ];
        specialArgs = {
          inherit hostVariables inputs system;
        };
      };
  in {
    nixosConfigurations = {
      work = mkNixosConfiguration {
        modules = [./hosts/work];
        hostVariables = import ./hosts/work/variables.nix;
      };
      wsl = mkNixosConfiguration {
        modules = [
          ./hosts/wsl
          inputs.nixos-wsl.nixosModules.wsl
        ];
        hostVariables = import ./hosts/wsl/variables.nix;
      };
      homelab = mkNixosConfiguration {
        modules = [./hosts/homelab];
        hostVariables = import ./hosts/homelab/variables.nix;
      };
      desktop = mkNixosConfiguration {
        modules = [./hosts/desktop];
        hostVariables = import ./hosts/desktop/variables.nix;
      };
      thinkpad = mkNixosConfiguration {
        modules = [./hosts/thinkpad];
        hostVariables = import ./hosts/thinkpad/variables.nix;
      };
      raspberry-pi = mkMinimalNixosConfiguration {
        modules = [./hosts/raspberry-pi];
        hostVariables = import ./hosts/raspberry-pi/variables.nix;
      };
    };
    overlays = import ./overlays.nix inputs;
  };
}
