{ lib, ... }: {
  programs.zsh = {
    enable = true;
    initExtra = lib.mkBefore ''
      # Custom contents
      echo "Custom contents"
    '';
    zprof.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileRegex home-files/.zshrc '^zmodload zsh/zprof'
  '';
}
