{ pkgs, ... }: {
  config = {
    programs.scmpuff.enable = true;
    programs.bash.enable = true;

    nmt.script = ''
      assertFileContent \
        home-files/.zshrc \
        'eval "$(${pkgs.gitAndTools.scmpuff}/bin/scmpuff init -s)"'
      assertFileContent \
        home-files/.bashrc \
        'eval "$(${pkgs.gitAndTools.scmpuff}/bin/scmpuff init -s)"'
    '';
  };
}
