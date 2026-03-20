{
  programs.riff = {
    enable = true;
    enableGitIntegration = true;
    commandLineOptions = [ "--no-adds-only-special" ];
  };

  programs.git.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContains home-files/.config/git/config '[pager]'
    assertFileContains home-files/.config/git/config 'diff = "riff"'
    assertFileContains home-files/.config/git/config 'log = "riff"'
    assertFileContains home-files/.config/git/config 'show = "riff"'
    assertFileContains home-files/.config/git/config '[interactive]'
    assertFileContains home-files/.config/git/config 'diffFilter = "riff --color=on"'
  '';
}
