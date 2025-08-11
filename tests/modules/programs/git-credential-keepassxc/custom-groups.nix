{
  programs.git.enable = true;
  programs.git-credential-keepassxc = {
    enable = true;
    groups = [
      "A"
      "B"
    ];
  };

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileRegex home-files/.config/git/config 'helper = "\S*/bin/git-credential-keepassxc --group A --group B"'
  '';
}
