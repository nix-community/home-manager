{ lib, ... }:
let
  inherit (import ./utils.nix lib) assertMetaFile metaName;
in
{
  # some examples from the website, adapted for the library
  config = {
    programs.pegasus-frontend = {
      enable = true;
      collections = {
        "Super Nintendo Entertainment System" = {
          launch = ''snes9x "{file.path}"'';
          extensions = [
            "7z"
            "bin"
            "smc"
            "sfc"
            "fig"
            "swc"
            "mgd"
            "zip"
            "bin"
          ];
          ignoreFiles = [
            "buggygame.bin"
            "duplicategame.bin"
          ];
        };
        "Platformer games" = {
          files = [
            "mario1.bin"
            "mario2.bin"
            "mario3.bin"
          ];
        };
        "Multi-game carts" = {
          regex = ''\d+.in.1'';
        };
      };
      games = [
        {
          title = "super neat game";
          collections = [ "Multi-game carts" ];
          files = [ "test" ];
        }
      ];
    };

    nmt.script = lib.concatStringsSep "\n" [
      (assertMetaFile (metaName "Super Nintendo Entertainment System") ''
        collection: Super Nintendo Entertainment System
        extensions: 7z, bin, smc, sfc, fig, swc, mgd, zip, bin
        ignore-file: buggygame.bin
        ignore-file: duplicategame.bin
        launch: snes9x "{file.path}"
      '')
      (assertMetaFile (metaName "Platformer games") ''
        collection: Platformer games
        file: mario1.bin
        file: mario2.bin
        file: mario3.bin
        launch: {file.path}
      '')
      (assertMetaFile (metaName "Multi-game carts") ''
        collection: Multi-game carts
        file: test
        launch: {file.path}
        regex: \d+.in.1
      '')
      (assertMetaFile "games.metadata.pegasus.txt" ''
        game: super neat game
        file: test
      '')
    ];
  };
}
