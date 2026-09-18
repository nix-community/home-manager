{
  programs.git.enable = true;
  programs.git-credential-keepassxc = {
    enable = true;
    unlock = {
      enable = true;
      retries = 5;
      interval = 3000;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileRegex home-files/.config/git/config 'helper = "\S*/bin/git-credential-keepassxc --git-groups --unlock 5,3000"'
  '';
}
