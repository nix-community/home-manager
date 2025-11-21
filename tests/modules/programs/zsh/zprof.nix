{
  config = {
    programs.zsh = {
      enable = true;
      zprof.enable = true;
    };

    test.stubs.zsh = { };

    nmt.script = ''
      assertFileRegex home-files/.zshrc 'zmodload zsh/zprof'
      assertFileRegex home-files/.zshrc '^zprof$'
    '';
  };
}
