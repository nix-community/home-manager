{ ... }:

{
  services.snixembed = {
    enable = true;
    beforeUnits = [ "safeeyes.service" ];
  };

  test.stubs = { snixembed = { outPath = "/snixembed"; }; };

  nmt.script = ''
    assertFileContent \
      home-files/.config/systemd/user/snixembed.service \
      ${./basic-configuration.service}
  '';
}
