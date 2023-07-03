{ config, ... }: {
  config = {
    programs.ripgrep-all = {
      enable = true;
      package = config.lib.test.mkStubPackage { name = "ripgrep-all"; };
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/ripgrep-all/config.jsonc
      assertPathNotExists 'home-files/Library/Application Support/ripgrep-all/config.jsonc'
    '';
  };
}
