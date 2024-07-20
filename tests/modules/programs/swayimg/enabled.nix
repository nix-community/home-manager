{ config, ... }: {
  programs.swayimg = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/swayimg/config
  '';
}
