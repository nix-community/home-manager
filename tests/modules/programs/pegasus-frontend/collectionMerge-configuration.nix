{ lib, ... }:
let
  metaName = name: "${lib.substring 0 32 (builtins.hashString "sha256" name)}.metadata.pegasus.txt";
  assertMetaFile =
    name: expected:
    lib.concatStringsSep "\n" [
      "assertFileExists /nix/store/*-pegasus-metadata/${name}"
      "assertFileContent /nix/store/*-pegasus-metadata/${name} ${./collectionMerge-${expected}.txt}"
    ];
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
      ${assertMetaFile (metaName "collection abd") "abd"}
      ${assertMetaFile (metaName "collection bc") "bc"}
      ${assertMetaFile (metaName "collection d") "d"}
      ${assertMetaFile "games.metadata.pegasus.txt" "game"}
    '';
  };
}
