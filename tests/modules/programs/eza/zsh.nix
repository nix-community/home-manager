{
  programs = {
    zsh.enable = true;

    eza = {
      enable = true;
      enableZshIntegration = true;
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
      icons = "auto";
      git = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      "alias -- eza='eza --icons auto --git --group-directories-first --header'"
    assertFileContains \
      home-files/.zshrc \
      "alias -- ls=eza"
    assertFileContains \
      home-files/.zshrc \
      "alias -- ll='eza -l'"
    assertFileContains \
      home-files/.zshrc \
      "alias -- la='eza -a'"
    assertFileContains \
      home-files/.zshrc \
      "alias -- lt='eza --tree'"
    assertFileContains \
      home-files/.zshrc \
      "alias -- lla='eza -la'"
  '';
}
