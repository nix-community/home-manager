{ ... }:

{
  programs = {
    carapace.enable = true;
    fish.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileRegex home-files/.config/fish/config.fish \
      '/nix/store/.*carapace.*/bin/carapace _carapace fish \| source'

    # Check whether completions are overridden.
    assertFileExists home-files/.config/fish/completions/git.fish
    assertFileContent home-files/.config/fish/completions/git.fish /dev/null
  '';
}
