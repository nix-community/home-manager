{ pkgs, ... }: {
  config = {
    programs = {
      scmpuff.enable = true;
      bash.enable = true;
    };

    nmt.script = ''
      assertFileExists home-files/.bashrc
      assertFileContains \
        home-files/.bashrc \
        'eval "$(${pkgs.gitAndTools.scmpuff}/bin/scmpuff init -s)"'
    '';
  };
}
