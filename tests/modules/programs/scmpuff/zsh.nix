{ pkgs, ... }: {
  config = {
    programs = {
      scmpuff.enable = true;
      zsh.enable = true;
    };

    nixpkgs.overlays =
      [ (self: super: { zsh = pkgs.writeScriptBin "dummy" ""; }) ];

    nmt.script = ''
      assertFileExists home-files/.zshrc
      assertFileContains \
        home-files/.zshrc \
        'eval "$(${pkgs.scmpuff}/bin/scmpuff init -s)"'
    '';
  };
}
