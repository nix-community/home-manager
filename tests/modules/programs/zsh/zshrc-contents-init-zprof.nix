{ lib, ... }: {
  programs.zsh = {
    enable = true;
    initContent = lib.mkBefore ''
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
