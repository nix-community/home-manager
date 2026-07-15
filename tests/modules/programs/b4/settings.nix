{
  programs.git.enable = true;

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
  '';
}
