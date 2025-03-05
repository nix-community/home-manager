{ lib, ... }: {
  programs.zsh = {
    enable = true;
    initExtra = lib.mkBefore ''
      # Custom contents
      echo "Custom contents"
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileRegex home-files/.zshrc $'^# Custom contents\necho "Custom contents"'
  '';
}
