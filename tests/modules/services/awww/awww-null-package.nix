{
  services.awww = {
    enable = true;
    package = null;
  };

  test.stubs.awww = {
    outPath = null;
    buildScript = ''
      mkdir -p $out/bin
      touch $out/bin/awww $out/bin/awww-daemon
    '';
  };

  nmt.script = ''
    assertPathNotExists home-path/bin/awww
    assertPathNotExists home-path/bin/awww-daemon
    assertPathNotExists home-files/.config/systemd/user/awww.service
  '';
}
