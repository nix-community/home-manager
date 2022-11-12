{ config, ... }: {
  programs.swaylock = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/swaylock/config
  '';
}
