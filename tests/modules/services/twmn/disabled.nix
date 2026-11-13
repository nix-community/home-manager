{ config, ... }:
{
  services.twmn = {
    settings.main.arbitrary = "ignored";
    text.font.package = config.lib.test.mkStubPackage {
      name = "twmn-disabled-font";
      buildScript = ''
        mkdir -p $out/share/fonts
        touch $out/share/fonts/twmn-disabled-font-marker
      '';
    };
  };

  test.stubs.twmn = {
    outPath = null;
    buildScript = ''
      mkdir -p $out/bin
      touch $out/bin/twmnd
    '';
  };

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertPathNotExists home-files/.config/twmn/twmn.conf
    assertPathNotExists home-files/.config/systemd/user/twmnd.service
    assertPathNotExists home-path/bin/twmnd
    assertPathNotExists home-path/share/fonts/twmn-disabled-font-marker
  '';
}
