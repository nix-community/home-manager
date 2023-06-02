{ config, ... }: {
  config = {
    programs.rtx = {
      package = config.lib.test.mkStubPackage { name = "rtx"; };
      enable = true;
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/rtx/config.toml
    '';
  };
}
