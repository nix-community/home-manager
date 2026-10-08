{
  config = {
    programs.zsh = {
      enable = true;

      oh-my-zsh = {
        enable = true;
        custom = "$HOME/extra/zsh";
        theme = "sigma";
      };
    };

    home.file.omz-zsh-theme = {
      source = builtins.toFile "sigma.zsh-theme" ''
        echo sigma
      '';
      target = "extra/zsh/themes/sigma.zsh-theme";
    };

    test.stubs = {
      oh-my-zsh = { };
      zsh = { };
    };

    nmt.script = ''
      assertFileContains home-files/.zshrc 'ZSH_CUSTOM="$HOME/extra/zsh"'
      assertFileContains home-files/.zshrc 'ZSH_THEME=sigma'
      assertFileExists home-files/extra/zsh/themes/sigma.zsh-theme
    '';
  };
}
