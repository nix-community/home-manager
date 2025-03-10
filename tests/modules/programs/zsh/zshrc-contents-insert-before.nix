{ lib, ... }: {
  programs.zsh = {
    enable = true;
    initContent = lib.mkBefore ''
      # Custom contents
      echo "Custom contents"
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileRegex home-files/.zshrc $'^# Custom contents\necho "Custom contents"'
  '';
}
