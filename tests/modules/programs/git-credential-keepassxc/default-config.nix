{
  programs.git.enable = true;
  programs.git-credential-keepassxc.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileRegex home-files/.config/git/config 'helper = "\S*/bin/git-credential-keepassxc --git-groups"'
  '';
}
