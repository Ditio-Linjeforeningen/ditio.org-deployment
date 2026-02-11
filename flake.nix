{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, nixpkgs, disko, nixos-facter-modules, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
      ];

      flake.nixosConfigurations.server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./server/configuration.nix
        ];
      };

      perSystem = { pkgs, system, ... }: {
        packages.nixos-anywhere-bootstrap = pkgs.writeShellApplication {
          name = "nixos-anywhere-bootstrap";

          runtimeInputs = [ pkgs.nixos-anywhere ];

          text = ''
            #!/usr/bin/env bash
            set -euo pipefail

            if [ -z "''${SERVER_HOST:-}" ] || [ -z "''${SSH_BOOTSTRAP_KEY:-}" ]; then
              echo "ERROR: SERVER_HOST and SSH_BOOTSTRAP_KEY must be set"
              exit 1
            fi

            mkdir -p ~/.ssh
            echo "$SSH_BOOTSTRAP_KEY" > ~/.ssh/id_ed25519
            chmod 600 ~/.ssh/id_ed25519

            # Optionally add host to known_hosts to avoid prompts
            ssh-keyscan -H "$SERVER_HOST" >> ~/.ssh/known_hosts

            echo "Bootstrapping NixOS server at $SERVER_HOST using SSH key..."

            nixos-anywhere --flake .#server root@$SERVER_HOST --ssh-key ~/.ssh/id_ed25519 \
              --generate-hardware-config nixos-generate-config ./hardware-configuration.nix
          '';
        };
      };
    };
}