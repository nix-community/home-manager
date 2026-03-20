{
  programs = {
    scmpuff = {
      enable = true;
      enableBashIntegration = false;
      enableZshIntegration = false;
    };
    bash.enable = true;
    zsh.enable = true;
  };

  nmt.script = ''
    assertFileNotRegex home-files/.zshrc '@scmpuff@'
    assertFileNotRegex home-files/.bashrc '@scmpuff@'
  '';
}
