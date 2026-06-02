{ lib, ... }:
let
  inherit (import ./utils.nix lib) assertMetaFile metaName;
in
{
  # test favorites management
  config = {
    programs.pegasus-frontend = {
      enable = true;
      collections = {
        "coll" = { };
      };
      games = [
        {
          title = "Game A";
          collections = [ "coll" ];
          files = [ "a" ];
          favorite = true;
        }
        {
          title = "Game B";
          collections = [ "coll" ];
          files = [ "b" ];
        }
        {
          title = "Game C";
          collections = [ "coll" ];
          files = [ "c" ];
          favorite = true;
        }
        {
          title = "Game D";
          collections = [ "coll" ];
          files = [ "d" ];
        }
        {
          title = "Game E";
          collections = [ "coll" ];
          files = [ "e" ];
        }
      ];
    };

    nmt.script = ''
      cfg=home-files/.config/pegasus-frontend

      ${assertMetaFile (metaName "coll") ''
        collection: coll
        file: a
        file: b
        file: c
        file: d
        file: e
        launch: {file.path}
      ''}
      ${assertMetaFile "games.metadata.pegasus.txt" ''
        game: Game A
        file: a


        game: Game B
        file: b


        game: Game C
        file: c


        game: Game D
        file: d


        game: Game E
        file: e
      ''}

      assertFileExists $cfg/favorites.txt
      assertFileContent $cfg/favorites.txt ${builtins.toFile "favorites.txt" "a\nc"}
    '';
  };
}
