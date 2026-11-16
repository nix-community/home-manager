{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.twmn = {
    enable = true;
    duration = lib.mkIf false 42;
    screen = lib.mkIf false 0;
    window.animation.easeIn = lib.mkIf false { };
    settings = lib.mkDefault {
      main.arbitrary = "modern";
      gui = {
        font_size = 18;
        offset_x = "+12";
      };
      custom = {
        arbitrary = "value";
        enabled = true;
        count = 3;
        ratio = 1.5;
      };
    };
    text.font.package = config.lib.test.mkStubPackage {
      name = "twmn-font";
      buildScript = ''
        mkdir -p $out/share/fonts
        touch $out/share/fonts/twmn-font-marker
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

  assertions = [
    {
      assertion = !(config.services.twmn.settings.main ? port);
      message = "the generated-file port fallback must not populate settings";
    }
  ];

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertFileContent home-files/.config/twmn/twmn.conf ${./modern-settings.conf}
    assertFileExists home-files/.config/systemd/user/twmnd.service
    assertFileExists home-path/bin/twmnd
    assertFileExists home-path/share/fonts/twmn-font-marker
    assertFileRegex home-files/.config/systemd/user/twmnd.service 'ExecStart=${pkgs.twmn}/bin/twmnd'
  '';
}
