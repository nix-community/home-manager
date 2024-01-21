{ config, ... }: {
  config = {
    programs.mise = {
      package = config.lib.test.mkStubPackage { name = "mise"; };
      enable = true;
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/mise/config.toml
      assertPathNotExists home-files/.config/mise/settings.toml
    '';
  };
}
