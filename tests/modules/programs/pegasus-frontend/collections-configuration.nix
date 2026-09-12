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
          extensions = lib.concatStringsSep ", " [
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
          ignore-files = [
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
        PlayStation = {
          extension = "iso";
          files = [
            "specialgame1.bin"
            "specialgame2.ext"
          ];
          ignore-file = "buggygame.iso";
          launch = ''myemulator "{file.path}"'';
        };
      };
      games = [
        {
          title = "super neat game";
          collections = [ "Multi-game carts" ];
          files = [ "test" ];
        }
        {
          title = "Final Fantasy VII";
          sort_title = "Final Fantasy 7";
          files = [
            "ffvii_disc1.iso"
            "ffvii_disc2.iso"
          ];
          developer = "Square";
          genre = "Role-playing";
          players = 1;
          rating = "92%";
          description = ''
            Final Fantasy VII is a 1997 role-playing video game developed by
            Square for the PlayStation console. It is the seventh main installment in the
            Final Fantasy series.

            The games story follows Cloud Strife, a mercenary who joins an eco-terrorist
            organization to stop a world-controlling megacorporation from using the planets
            life essence as an energy source.
          '';
          x-scrape-source = "SomeScraper";
        }
      ];
    };

    nmt.script = lib.concatStringsSep "\n" [
      (assertMetaFile (metaName "Super Nintendo Entertainment System") ''
        collection: Super Nintendo Entertainment System
        extensions: 7z, bin, smc, sfc, fig, swc, mgd, zip, bin
        ignore-files: buggygame.bin
        ignore-files: duplicategame.bin
        launch: snes9x "{file.path}"
      '')
      (assertMetaFile (metaName "Platformer games") ''
        collection: Platformer games
        files: mario1.bin
        files: mario2.bin
        files: mario3.bin
        launch: {file.path}
      '')
      (assertMetaFile (metaName "Multi-game carts") ''
        collection: Multi-game carts
        files: test
        launch: {file.path}
        regex: \d+.in.1
      '')
      (assertMetaFile (metaName "PlayStation") ''
        collection: PlayStation
        extension: iso
        files: specialgame1.bin
        files: specialgame2.ext
        ignore-file: buggygame.iso
        launch: myemulator "{file.path}"
      '')
      (assertMetaFile "games.metadata.pegasus.txt" ''
        game: super neat game
        files: test


        game: Final Fantasy VII
        description:${" "}
        ${"\t"}Final Fantasy VII is a 1997 role-playing video game developed by
        ${"\t"}Square for the PlayStation console. It is the seventh main installment in the
        ${"\t"}Final Fantasy series.
        ${"\t"}.
        ${"\t"}The games story follows Cloud Strife, a mercenary who joins an eco-terrorist
        ${"\t"}organization to stop a world-controlling megacorporation from using the planets
        ${"\t"}life essence as an energy source.
        developer: Square
        files: ffvii_disc1.iso
        files: ffvii_disc2.iso
        genre: Role-playing
        players: 1
        rating: 92%
        sort_title: Final Fantasy 7
        x-scrape-source: SomeScraper
      '')
    ];
  };
}
