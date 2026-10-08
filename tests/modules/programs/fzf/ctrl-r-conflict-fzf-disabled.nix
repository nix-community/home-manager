{ config, ... }:

{
  programs = {
    atuin = {
      enable = true;
      enableZshIntegration = true;
      package = config.lib.test.mkStubPackage { name = "atuin"; };
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      historyWidget.command = "";
      package = config.lib.test.mkStubPackage {
        name = "fzf";
        version = "0.73.0";
      };
    };

    zsh.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
  '';
}
