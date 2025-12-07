{
  description = "NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # Create pkgs instances with overlay for both architectures
      pkgs-x86 = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
        overlays = [ self.overlays.default ];
        crossSystem.system = "aarch64-linux";
      };

      pkgs-aarch64 = import nixpkgs {
        system = "aarch64-linux";
        config.allowUnfree = true;
        overlays = [ self.overlays.default ];
      };
    in
    {
      overlays.default = final: prev: {
        ubootRock5T = prev.callPackage ./pkgs/u-boot { };
      };

      nixosConfigurations = {
        rock-5t = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            {
              nixpkgs.localSystem.system = "x86_64-linux";
              nixpkgs.crossSystem.system = "aarch64-linux";
              nixpkgs.overlays = [ self.overlays.default ];
            }
            ./configuration.nix
            ./repart.nix
            "${nixpkgs}/nixos/modules/profiles/minimal.nix"
          ];
          specialArgs = {
          };
        };
      };

      packages.x86_64-linux.default = self.nixosConfigurations.rock-5t.config.system.build.image;
      packages.aarch64-linux.default = self.nixosConfigurations.rock-5t.config.system.build.image;

      packages.x86_64-linux.u-boot = pkgs-x86.ubootRock5T;
      packages.aarch64-linux.u-boot = pkgs-aarch64.ubootRock5T;

      packages.x86_64-linux.flash = (pkgs.callPackage ./pkgs/flash { targetPkgs = if system == "x86_64-linux" then pkgs-x86 else pkgs-aarch64; }).flash;

      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [
          rkdeveloptool
        ];
      };
    };
}
