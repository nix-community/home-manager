{ lib, ... }: {
  programs.zsh = {
    enable = true;

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # High priority (mkBefore)
        echo "High priority content"
      '')

      (lib.mkAfter ''
        # Low priority (mkAfter)
        echo "Low priority content"
      '')

      ''
        # Default priority
        echo "Default priority content"
      ''
    ];

    zprof.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc

    assertFileContains home-files/.zshrc "zmodload zsh/zprof"
    assertFileContains home-files/.zshrc "High priority content"
    assertFileContains home-files/.zshrc "Default priority content"
    assertFileContains home-files/.zshrc "Low priority content"

    assertFileRegex home-files/.zshrc '^zmodload zsh/zprof'
    assertFileRegex home-files/.zshrc 'echo "Low priority content"$'
  '';
}
