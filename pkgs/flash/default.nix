{
  pkgs,
  targetPkgs,
  ...
}:
let 
  system = pkgs.stdenv.hostPlatform.system;
  rkdeveloptool = pkgs.rkdeveloptool;
  u-boot = targetPkgs.ubootRock5T;
in
rec {


  flash = pkgs.writeShellScriptBin "flash" ''
    #!/usr/bin/env bash
    set -e
    printf "Flashing U-Boot to Rock 5T...\nEnsure command is run with permissions to access rk board.\n\n"

    printf "Enter maskrom mode on the Rock 5T by powering off the device, holding the maskrom button, and powering it on while holding the reset button for 5 seconds.\n"
    printf "Press Enter to continue once the device is in maskrom mode..."
    read -r _

    printf "Searching for device...\n"
    ${rkdeveloptool}/bin/rkdeveloptool ld
    printf "\nFound Rock 5T device.\n"

    ${rkdeveloptool}/bin/rkdeveloptool db ${./rk3588_spl_loader_v1.15.113.bin}
    ${rkdeveloptool}/bin/rkdeveloptool rci

    printf "\nErasing SPI Flash\n"
    ${rkdeveloptool}/bin/rkdeveloptool cs 9
    ${rkdeveloptool}/bin/rkdeveloptool ef
    
    printf "\nUploading U-Boot Image...\n"
    ${rkdeveloptool}/bin/rkdeveloptool wl 0 ${u-boot}/u-boot-rockchip-spi.bin

    printf "\nU-Boot successfully flashed to Rock 5T.\n"
    printf "Resetting.\n"
    ${rkdeveloptool}/bin/rkdeveloptool rd
  '';
}