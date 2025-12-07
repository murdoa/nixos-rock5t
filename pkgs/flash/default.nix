{
  pkgs,
  pkgsCross,
  nixosConfig,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  rkdeveloptool = pkgs.rkdeveloptool;
  u-boot = pkgsCross.ubootRock5T;
  pv = pkgs.pv;
in
rec {

  flash-uboot = pkgs.writeShellScriptBin "flash" ''
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

  flash-sd = pkgs.writeShellScriptBin "flash-sd" ''
    #!/usr/bin/env bash
    set -e
    printf "Flashing U-Boot to SD Card for Rock 5T...\n"
    printf "Ensure the SD card is inserted and identify the device path (e.g., /dev/sdX).\n\n"

    if [ -z "$1" ]; then
      printf "Usage: flash-sd <device-path>\n"
      exit 1
    fi

    DEVICE_PATH="$1"

    printf "Warning: This will overwrite data on $DEVICE_PATH. Proceed? (y/n): "
    read -r CONFIRM
    if [ "$CONFIRM" != "y" ]; then
      printf "Aborting.\n"
      exit 1
    fi

    printf "Writing U-Boot to $DEVICE_PATH...\n"
    ${pv}/bin/pv ${nixosConfig.config.system.build.image}/image.raw | sudo dd of=$DEVICE_PATH bs=4M oflag=sync

    printf "U-Boot successfully written to $DEVICE_PATH.\n"
  '';
}
