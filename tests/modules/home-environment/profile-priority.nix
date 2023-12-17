{ config, lib, pkgs, ... }:
with lib; {
  meta.priority = 4;

  nmt.script = ''
    assertFileContains activate \
      'HM_PACKAGE_PRIORITY=''${HM_PACKAGE_PRIORITY:-${
        toString config.meta.priority
      }}'
  '';
}
