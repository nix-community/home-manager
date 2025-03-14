{ config, ... }: {
  config = {
    programs.bottom = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/bottom
    '';
  };
}
