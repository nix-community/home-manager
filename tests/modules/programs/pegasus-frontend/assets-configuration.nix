{ lib, ... }:
let
  inherit (import ./utils.nix lib) assertMetaFile;
in
{
  # test asset management
  config = {
    programs.pegasus-frontend = {
      enable = true;
      collections._ = { };
      games = [
        {
          title = "My Game";
          files = [
            (builtins.toFile "mygame.txt" "")
          ];
          assets = {
            boxFront = builtins.toFile "boxfront.png" "";
            logo = [
              "./logo.png"
              "./other-logo.png"
            ];
            tile = ./fake-image.txt;
          };
        }
      ];
    };

    nmt.script = assertMetaFile "games.metadata.pegasus.txt" ''
      game: My Game
      assets.boxFront: /nix/store/00000000000000000000000000000000-boxfront.png
      assets.logo: ./logo.png
      assets.logo: ./other-logo.png
      assets.tile: /nix/store/00000000000000000000000000000000-fake-image.txt
      file: /nix/store/00000000000000000000000000000000-mygame.txt
    '';
  };
}
