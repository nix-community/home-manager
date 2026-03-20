{
  programs = {
    fish.enable = true;

    eza = {
      enable = true;
      enableFishIntegration = true;
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
      icons = "auto";
      git = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileContains \
      home-files/.config/fish/config.fish \
      "alias eza 'eza --icons auto --git --group-directories-first --header'"
    assertFileContains \
      home-files/.config/fish/config.fish \
      "alias ls eza"
    assertFileContains \
      home-files/.config/fish/config.fish \
      "alias ll 'eza -l'"
    assertFileContains \
      home-files/.config/fish/config.fish \
      "alias la 'eza -a'"
    assertFileContains \
      home-files/.config/fish/config.fish \
      "alias lt 'eza --tree'"
    assertFileContains \
      home-files/.config/fish/config.fish \
      "alias lla 'eza -la'"
  '';
}
