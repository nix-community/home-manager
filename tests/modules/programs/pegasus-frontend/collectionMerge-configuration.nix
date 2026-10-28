{ lib, ... }:
let
  inherit (import ./utils.nix lib) assertMetaFile metaName;
in
{
  # testing the merging of games into their assigned collections
  config = {
    programs.pegasus-frontend = {
      enable = true;
      collections = {
        "collection abd" = {
          launch = "{file.path}";
        };
        "collection bc" = {
          files = [
            "/b" # this should get merged with "c"
          ];
        };
        "collection d" = {
          not_a_setting = "testing";
        };
        "collection e" = {
          # if files isnt a list, it should still get properly merged with other files
          files = "/s";
        };
      };
      games = [
        {
          title = "game a";
          collections = [ "collection abd" ];
          files = [ "/a" ];
        }
        {
          title = "game b";
          collections = [
            "collection abd"
            "collection bc"
          ];
          files = [ "/b" ];
        }
        {
          title = "game c";
          collections = [ "collection bc" ];
          files = [ "/c" ];
          multi-key = [
            "v1"
            "v2"
          ];
        }
        {
          title = "game ad";
          collections = [
            "collection abd"
            "collection d"
          ];
          files = [
            "/a"
            "/d"
          ];
        }
        {
          title = "game se";
          collections = [ "collection e" ];
          files = [
            "/e"
            "/s" # should get deduplicated from the collection above
          ];
        }
      ];
    };

    nmt.script = ''
      ${assertMetaFile (metaName "collection abd") ''
        collection: collection abd
        files: /a
        files: /b
        files: /d
        launch: {file.path}
      ''}
      ${assertMetaFile (metaName "collection bc") ''
        collection: collection bc
        files: /b
        files: /c
        launch: {file.path}
      ''}
      ${assertMetaFile (metaName "collection d") ''
        collection: collection d
        files: /a
        files: /d
        launch: {file.path}
        not_a_setting: testing
      ''}
      ${assertMetaFile (metaName "collection e") ''
        collection: collection e
        files: /s
        files: /e
        launch: {file.path}
      ''}
      ${assertMetaFile "games.metadata.pegasus.txt" ''
        game: game a
        files: /a


        game: game b
        files: /b


        game: game c
        files: /c
        multi-key: v1
        multi-key: v2


        game: game ad
        files: /a
        files: /d


        game: game se
        files: /e
        files: /s
      ''}
    '';
  };
}
