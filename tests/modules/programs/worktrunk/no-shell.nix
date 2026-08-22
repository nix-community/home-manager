{
  programs = {
    worktrunk = {
      enable = true;
      enableZshIntegration = false;
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableNushellIntegration = false;
    };
    zsh.enable = true;
    bash.enable = true;
    fish.enable = true;
  };

  nmt.script = ''
    assertFileNotRegex home-files/.zshrc 'eval "$(@worktrunk@ config shell init zsh)"'
    assertFileNotRegex home-files/.bashrc 'eval "$(@worktrunk@ config shell init bash)"'
    assertFileNotRegex home-files/.config/fish/config.fish 'eval "$(@worktrunk@ config shell init fish)"'
  '';
}
