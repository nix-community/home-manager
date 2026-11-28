{
  wayland.windowManager.dwl = {
    enable = true;
    systemd.enable = true;
  };

  test.stubs.dwl = {
    outPath = null;
    buildScript = ''
      mkdir -p $out/bin
      touch $out/bin/dwl
    '';
  };

  nmt.script = ''
    assertFileExists home-path/bin/dwl
    assertFileContent "$(normalizeStorePaths home-path/bin/dwl)" ${./dwl-expected.sh}
    assertFileExists home-files/.config/systemd/user/dwl-session.target
  '';
}
