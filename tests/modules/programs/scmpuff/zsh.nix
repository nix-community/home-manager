{ pkgs, ... }: {
  config = {
    programs = {
      scmpuff.enable = true;
      zsh.enable = true;
    };

    test.stubs.zsh = { };

    nmt.script = ''
      assertFileExists home-files/.zshrc
      assertFileContains \
        home-files/.zshrc \
        'eval "$(${pkgs.scmpuff}/bin/scmpuff init -s)"'
    '';
  };
}
