{
  wayland.windowManager.dwl = {
    enable = true;
    systemd.enable = false;
  };

  test.stubs.dwl = {
    outPath = null;
    buildScript = ''
      mkdir -p $out/bin
      touch $out/bin/dwl
    '';
  };

  nmt.script = ''
    touch emptyFile

    assertFileExists home-path/bin/dwl
    assertFileContent home-path/bin/dwl emptyFile
    assertPathNotExists home-files/.config/systemd/user/dwl-session.target
  '';
}
