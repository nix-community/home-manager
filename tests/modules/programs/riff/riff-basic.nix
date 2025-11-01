{
  programs.riff = {
    enable = true;
    commandLineOptions = [ "--no-adds-only-special" ];
  };
  programs.git.enable = true;

  nmt.script = ''
    # Git config should NOT contain riff configuration since enableGitIntegration is false by default
    assertFileNotRegex home-files/.config/git/config '\[pager\]'
    assertFileNotRegex home-files/.config/git/config 'diff = riff'
  '';
}
