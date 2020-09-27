{ pkgs, ... }:

{
  config = {
    programs.feh.enable = true;

    nixpkgs.overlays =
      [ (self: super: { feh = pkgs.writeScriptBin "dummy-feh" ""; }) ];

    nmt.script = ''
      assertPathNotExists home-files/.config/feh/buttons
      assertPathNotExists home-files/.config/feh/keys
    '';
  };
}
