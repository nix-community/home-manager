{ config, ... }: {
  config = {
    programs.ripgrep = {
      enable = true;
      package = config.lib.test.mkStubPackage { name = "ripgrep"; };
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/ripgrep/ripgreprc
    '';
  };
}
