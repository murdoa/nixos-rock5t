{
  armTrustedFirmwareRK3588,
  fetchFromGitHub,
  buildUBoot,
  rkbin,
}:
buildUBoot {
  version = "v2026.01-rc2";
  defconfig = "rock5t-rk3588_defconfig";
  extraMeta.platforms = [ "aarch64-linux" ];
  src = fetchFromGitHub {
    owner = "u-boot";
    repo = "u-boot";
    rev = "v2026.01-rc2";
    hash = "sha256-YnLmvn/niTd/39zXu/FECpGYSTZ3sVuN3Zv3mBWGAa0=";
  };
  BL31 = "${armTrustedFirmwareRK3588}/bl31.elf";
  ROCKCHIP_TPL = rkbin.TPL_RK3588;
  filesToInstall = [
    "u-boot.itb"
    "idbloader.img"
    "u-boot-rockchip.bin"
    "u-boot-rockchip-spi.bin"
  ];
  # Override patches to exclude Raspberry Pi specific patches
  patches = [
    ./0001-add-rock-5t-rk3588_defconfig.patch
  ];
  extraPatches = [ ];
}
