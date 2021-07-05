{ pkgs, ... }: {
  config = {
    programs = {
      scmpuff = {
        enable = true;
        enableZshIntegration = false;
      };
      zsh.enable = true;
    };

    nmt.script = ''
      assertFileNotRegex home-files/.zshrc '${pkgs.scmpuff} init -s'
    '';
  };
}
