{
  services.snixembed = {
    enable = true;
    beforeUnits = [ "safeeyes.service" ];
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/systemd/user/snixembed.service \
      ${./basic-configuration.service}
  '';
}
