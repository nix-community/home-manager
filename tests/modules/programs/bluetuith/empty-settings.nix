{ config, ... }:
{
  config = {
    programs.bluetuith = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/bluetuith
    '';
  };
}
