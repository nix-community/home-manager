{ lib, ... }:
let
  metaName = name: "${lib.substring 0 32 (builtins.hashString "sha256" name)}.metadata.pegasus.txt";
  assertMetaFile =
    name: expected:
    lib.concatStringsSep "\n" [
      "assertFileExists /nix/store/*-pegasus-metadata/${name}"
      "assertFileContent /nix/store/*-pegasus-metadata/${name} ${./favorites-${expected}.txt}"
    ];
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

      ${assertMetaFile (metaName "coll") "coll"}
      ${assertMetaFile "games.metadata.pegasus.txt" "game"}

      assertFileExists $cfg/favorites.txt
      assertFileContent $cfg/favorites.txt ${builtins.toFile "favorites.txt" "a\nc"}
    '';
  };
}
