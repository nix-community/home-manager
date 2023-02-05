{ lib, pkgs, ... }:

{
  xsession.windowManager.herbstluftwm = { enable = true; };

  test.stubs.herbstluftwm = { };

  nmt.script = ''
    autostart=home-files/.config/herbstluftwm/autostart
    assertFileExists "$autostart"
    assertFileIsExecutable "$autostart"

    normalizedAutostart=$(normalizeStorePaths "$autostart")
    assertFileContent "$normalizedAutostart" ${./herbstluftwm-no-tags-autostart}
  '';
}
