{
  # settings lands in the [b4] section and coexists with the ordered-list form
  # of programs.git.settings, which a `programs.git.settings.b4` definition
  # would conflict with.
  programs.git = {
    enable = true;
    settings = [
      { core.whitespace = "trailing-space,space-before-tab"; }
    ];
  };

  programs.b4 = {
    enable = true;
    settings = {
      attestation-policy = "hardfail";
      midmask = "https://lore.kernel.org/all/%s";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContains home-files/.config/git/config '[b4]'
    assertFileContains home-files/.config/git/config 'attestation-policy = "hardfail"'
    assertFileContains home-files/.config/git/config 'midmask = "https://lore.kernel.org/all/%s"'
    assertFileContains home-files/.config/git/config '[core]'
    assertFileContains home-files/.config/git/config \
      'whitespace = "trailing-space,space-before-tab"'
  '';
}
