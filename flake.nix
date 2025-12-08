{
  description = "NixOS flake for Radxa Rock 5T SBC";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    radxa-overlays = {
      url = "github:radxa-pkg/radxa-overlays";
      flake = false;
    };
    ssh-keys = {
      url = "https://github.com/murdoa.keys";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ssh-keys,
      radxa-overlays,
      ...
    }@inputs:
    {
      overlays.default = final: prev: {
        ubootRock5T = prev.callPackage ./pkgs/u-boot { };
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        lib = nixpkgs.lib;

        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Create pkgs instances with overlay for all architectures
        pkgsCross =
          if system == "aarch64-linux" then
            pkgs
          else
            import nixpkgs {
              system = system;
              config.allowUnfree = true;
              overlays = [ self.overlays.default ];
              crossSystem.system = "aarch64-linux";
            };

        nixosConfig = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            {
              nixpkgs.localSystem.system = system;
              nixpkgs.crossSystem.system = "aarch64-linux";
              nixpkgs.overlays = [ self.overlays.default ];
            }
            ./configuration.nix
            ./repart.nix
            "${nixpkgs}/nixos/modules/profiles/minimal.nix"
          ];
          specialArgs = {
            inherit ssh-keys radxa-overlays;
          };
        };
      in
      {
        nixosConfigurations = {
          rock-5t = nixosConfig;
        };

        packages = rec {
          os = nixosConfig.config.system.build.toplevel;
          kernel = nixosConfig.config.system.build.kernel;
          image = nixosConfig.config.system.build.image;
          u-boot = pkgsCross.ubootRock5T;
        }
        // (pkgs.callPackage ./pkgs/flash {
          inherit pkgsCross;
          inherit nixosConfig;
        });

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            pv
            rkdeveloptool
          ];
        };
      }
    );
}
