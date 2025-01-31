{ pkgs, ... }:

{
  xdg.autostart = {
    enable = true;
    entries = [
      "${pkgs.test1}/share/applications/test1.desktop"
      "${pkgs.test2}/share/applications/test2.desktop"
    ];
  };

  test.stubs = {
    test1 = {
      outPath = null;
      buildScript = ''
        mkdir -p $out/share/applications
        echo test1 > $out/share/applications/test1.desktop
      '';
    };
    test2 = {
      outPath = null;
      buildScript = ''
        mkdir -p $out/share/applications
        echo test2 > $out/share/applications/test2.desktop
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/autostart/test1.desktop
    assertFileContent home-files/.config/autostart/test1.desktop \
      ${pkgs.test1}/share/applications/test1.desktop

    assertFileExists home-files/.config/autostart/test2.desktop
    assertFileContent home-files/.config/autostart/test2.desktop \
      ${pkgs.test2}/share/applications/test2.desktop
  '';
}
