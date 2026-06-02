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
            "b" # this should get merged with "c"
          ];
        };
        "collection d" = {
          extraConfig.not_a_setting = "testing";
        };
      };
      games = [
        {
          title = "game a";
          collections = [ "collection abd" ];
          files = [ "a" ];
        }
        {
          title = "game b";
          collections = [
            "collection abd"
            "collection bc"
          ];
          files = [ "b" ];
        }
        {
          title = "game c";
          collections = [ "collection bc" ];
          files = [ "c" ];
          extraConfig.multi-key = [
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
            "a"
            "d"
          ];
        }
      ];
    };

    nmt.script = ''
      ${assertMetaFile (metaName "collection abd") ''
        collection: collection abd
        file: a
        file: b
        file: d
        launch: {file.path}
      ''}
      ${assertMetaFile (metaName "collection bc") ''
        collection: collection bc
        file: b
        file: c
        launch: {file.path}
      ''}
      ${assertMetaFile (metaName "collection d") ''
        collection: collection d
        file: a
        file: d
        launch: {file.path}
        not_a_setting: testing
      ''}
      ${assertMetaFile "games.metadata.pegasus.txt" ''
        game: game a
        file: a


        game: game b
        file: b


        game: game c
        file: c
        multi-key: v1
        multi-key: v2


        game: game ad
        file: a
        file: d
      ''}
    '';
  };
}
