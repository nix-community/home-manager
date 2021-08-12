{ pkgs, ... }: {
  config = {
    programs = {
      scmpuff = {
        enable = true;
        enableBashIntegration = false;
        enableZshIntegration = false;
      };
      bash.enable = true;
      zsh.enable = true;
    };

    nixpkgs.overlays =
      [ (self: super: { zsh = pkgs.writeScriptBin "dummy" ""; }) ];

    nmt.script = ''
      assertFileNotRegex home-files/.zshrc '${pkgs.scmpuff} init -s'
      assertFileNotRegex home-files/.bashrc '${pkgs.scmpuff} init -s'
    '';
  };
}
