{
  programs.git.enable = true;
  programs.git-credential-keepassxc = {
    enable = true;
    hosts = [ "https://codeberg.org" ];
  };

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContains home-files/.config/git/config '[credential "https://codeberg.org"]'
    assertFileRegex home-files/.config/git/config 'helper = "\S*/bin/git-credential-keepassxc --git-groups"'
  '';
}
