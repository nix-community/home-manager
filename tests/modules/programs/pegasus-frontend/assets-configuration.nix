{ ... }:
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
            tile = ./assets-tile.txt;
          };
        }
      ];
    };

    nmt.script = ''
      assertFileExists /nix/store/*-pegasus-metadata/games.metadata.pegasus.txt
      assertFileContent $(normalizeStorePaths /nix/store/*-pegasus-metadata/games.metadata.pegasus.txt) ${./assets-game.txt}
    '';
  };
}
