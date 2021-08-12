{ pkgs, ... }: {
  config = {
    programs = {
      scmpuff = {
        enable = true;
        enableZshIntegration = false;
      };
      zsh.enable = true;
    };

    nixpkgs.overlays =
      [ (self: super: { zsh = pkgs.writeScriptBin "dummy" ""; }) ];

    nmt.script = ''
      assertFileNotRegex home-files/.zshrc '${pkgs.scmpuff} init -s'
    '';
  };
}
