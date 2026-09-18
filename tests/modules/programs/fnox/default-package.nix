{
  programs = {
    fnox = {
      enable = true;
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableNushellIntegration = false;
      enableZshIntegration = false;
      settings = { };
    };

    bash.enable = true;
    fish.enable = true;
    nushell.enable = true;
    zsh.enable = true;
  };

  test.stubs.fnox = {
    outPath = null;
    buildScript = ''
      mkdir -p "$out/bin"
      touch "$out/bin/fnox"
    '';
  };

  nmt.script = ''
    assertFileExists home-path/bin/fnox
    assertPathNotExists home-files/.config/fnox/config.toml

    assertFileNotRegex home-files/.bashrc 'fnox activate'
    assertFileNotRegex home-files/.config/fish/config.fish 'fnox activate'
    assertFileNotRegex home-files/.config/nushell/config.nu 'fnox activate'
    assertFileNotRegex home-files/.zshrc 'fnox activate'
  '';
}
