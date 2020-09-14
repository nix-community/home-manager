{ pkgs, ... }:

{
  config = {
    programs.ncmpcpp.enable = true;

    nixpkgs.overlays =
      [ (self: super: { ncmpcpp = pkgs.writeScriptBin "dummy-ncmpcpp" ""; }) ];

    nmt.script = ''
      assertPathNotExists home-files/.config/ncmpcpp/config

      assertPathNotExists home-files/.config/ncmpcpp/bindings
    '';
  };
}
