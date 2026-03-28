{ lib, ... }:
let
  metaName = name: "${lib.substring 0 32 (builtins.hashString "sha256" name)}.metadata.pegasus.txt";
  assertMetaFile =
    name: expected:
    lib.concatStringsSep "\n" [
      "assertFileExists /nix/store/*-pegasus-metadata/${name}"
      "assertFileContent /nix/store/*-pegasus-metadata/${name} ${./collections-${expected}.txt}"
    ];
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

    nmt.script = ''
      ${assertMetaFile (metaName "Super Nintendo Entertainment System") "snes"}
      ${assertMetaFile (metaName "Platformer games") "platformer"}
      ${assertMetaFile (metaName "Multi-game carts") "multi"}
      ${assertMetaFile "games.metadata.pegasus.txt" "game"}
    '';
  };
}
