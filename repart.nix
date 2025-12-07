{
  lib,
  config,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/image/repart.nix"
  ];

  systemd.repart.enable = true;
  systemd.repart.partitions."01-root".Type = "root";

  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.root = "gpt-auto";
  boot.initrd.supportedFilesystems.ext4 = true;

  boot.loader = {
    generic-extlinux-compatible.enable = lib.mkForce false;
    grub.enable = lib.mkForce false;
  };

  hardware.deviceTree.enable = true;
  hardware.deviceTree.name = "rockchip/rk3588-rock-5t";

  image.repart = {
    name = "image";
    partitions = {
      "01-esp" = {
        contents = {
          "/u-boot.itb".source = "${pkgs.ubootRock5T}/u-boot.itb";
          "/idbloader.img".source = "${pkgs.ubootRock5T}/idbloader.img";
          "/u-boot-rockchip.bin".source = "${pkgs.ubootRock5T}/u-boot-rockchip.bin";
          "/u-boot-rockchip-spi.bin".source = "${pkgs.ubootRock5T}/u-boot-rockchip-spi.bin";
          "/u-boot.bin".source = "${pkgs.ubootRock5T}/u-boot.bin";
        };
        repartConfig = {
          Type = "esp";
          Format = "vfat";
          Label = "ESP";
          SizeMinBytes = "512M";
        };
      };
      "02-root" = {
        storePaths = [ config.system.build.toplevel ];
        repartConfig = {
          Type = "root";
          Format = "ext4";
          Label = "nixos";
          Minimize = "guess";
          GrowFileSystem = true;
        };
      };
    };
  };
}
