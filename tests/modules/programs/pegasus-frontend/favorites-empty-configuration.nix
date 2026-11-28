{ lib, ... }:
let
  inherit (import ./utils.nix lib) assertMetaFile metaName;
in
{
  # an empty favorites list should still manage the file
  config = {
    programs.pegasus-frontend = {
      enable = true;
      favorites = [ ];
      collections = {
        "coll" = { };
      };
      games = [
        {
          title = "Game A";
          collections = [ "coll" ];
          files = [ "/a" ];
        }
      ];
    };

    nmt.script = ''
      cfg=home-files/.config/pegasus-frontend

      ${assertMetaFile (metaName "coll") ''
        collection: coll
        files: /a
        launch: {file.path}
      ''}

      # an empty favorites list still manages the file
      assertFileExists $cfg/favorites.txt
      assertFileContent $cfg/favorites.txt ${builtins.toFile "empty-favorites.txt" ""}
    '';
  };
}
