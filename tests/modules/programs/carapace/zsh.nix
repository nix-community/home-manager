{ ... }:

{
  programs = {
    carapace.enable = true;
    zsh.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileRegex home-files/.zshrc \
      'source <(/nix/store/.*carapace.*/bin/carapace _carapace zsh)'
  '';
}
