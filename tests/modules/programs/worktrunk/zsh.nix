{
  programs = {
    worktrunk.enable = true;
    zsh.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileRegex home-files/.zshrc \
      'eval "\$(@worktrunk@/bin/wt config shell init zsh)"'
  '';
}
