{ config, realPkgs, ... }:
let
  cfg = config.fonts.fontconfig.mutablePlaceholder;
in
{
  fonts.fontconfig.enable = true;
  fonts.fontconfig.mutablePlaceholder.enable = true;

  nmt.script = ''
    SYSTEMD_LOG_LEVEL=debug ${realPkgs.systemd}/bin/systemd-tmpfiles \
      -E \
      --root "$TEMPDIR/chroot" \
      --create \
      --remove \
      --boot \
      "$TESTED/home-files/.config/user-tmpfiles.d/home-manager.conf"

    assertFileExists "$TEMPDIR/chroot/${cfg.file}"
    assertFileNotRegex "$TEMPDIR/chroot/${cfg.file}" .
  '';

  test.stubs.systemd.outPath = null;
}
