{
  programs = {
    fnox = {
      enable = false;
      settings.env = "exec";
    };

    bash = {
      enable = true;
      initExtra = "# Bash marker";
    };
    fish = {
      enable = true;
      interactiveShellInit = "# Fish marker";
    };
    nushell = {
      enable = true;
      extraConfig = "# Nushell marker";
    };
    zsh = {
      enable = true;
      initContent = "# Zsh marker";
    };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/fnox/config.toml
    assertPathNotExists home-path/bin/fnox

    assertFileNotRegex home-files/.bashrc 'fnox activate'
    assertFileNotRegex home-files/.config/fish/config.fish 'fnox activate'
    assertFileNotRegex home-files/.config/nushell/config.nu 'fnox activate'
    assertFileNotRegex home-files/.zshrc 'fnox activate'
  '';
}
