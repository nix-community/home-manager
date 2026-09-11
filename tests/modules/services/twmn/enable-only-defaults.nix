{ config, lib, ... }:
{
  services.twmn = {
    enable = true;
    duration = lib.mkIf false 42;
    screen = lib.mkIf false 0;
    window.animation.easeIn = lib.mkIf false { };
    text.font.package = config.lib.test.mkStubPackage {
      name = "twmn-font";
      buildScript = ''
        mkdir -p $out/share/fonts
        touch $out/share/fonts/twmn-font-marker
      '';
    };
  };

  assertions = [
    {
      assertion = config.services.twmn.settings == { };
      message = "enabling twmn must leave settings empty";
    }
    {
      assertion = config.systemd.user.services.twmnd.Unit.X-Restart-Triggers == [ ];
      message = "unmanaged twmn configuration must not add restart triggers";
    }
  ];

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertPathNotExists home-files/.config/twmn/twmn.conf
    assertFileExists home-files/.config/systemd/user/twmnd.service
    assertFileExists home-path/share/fonts/twmn-font-marker
  '';
}
