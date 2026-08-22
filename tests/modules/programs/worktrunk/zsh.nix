{
  programs = {
    worktrunk.enable = true;
    worktrunk.enableZshIntegration = true;
    zsh.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'eval "$(@worktrunk@ config shell init zsh)"'
  '';
}
