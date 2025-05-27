{
  programs = {
    nushell.enable = true;

    eza = {
      enable = true;
      enableNushellIntegration = true;
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
      icons = "auto";
      git = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/nushell/config.nu
    assertFileContains \
      home-files/.config/nushell/config.nu \
      'alias "eza" = eza --icons auto --git --group-directories-first --header'
    assertFileContains \
      home-files/.config/nushell/config.nu \
      'alias "ls" = eza'
    assertFileContains \
      home-files/.config/nushell/config.nu \
      'alias "ll" = eza -l'
    assertFileContains \
      home-files/.config/nushell/config.nu \
      'alias "la" = eza -a'
    assertFileContains \
      home-files/.config/nushell/config.nu \
      'alias "lt" = eza --tree'
    assertFileContains \
      home-files/.config/nushell/config.nu \
      'alias "lla" = eza -la'
  '';
}
