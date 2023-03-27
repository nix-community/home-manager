{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.darcs;

in {
  meta.maintainers = with maintainers; [ chris-martin ];

  options = {
    programs.darcs = {
      enable = mkEnableOption "darcs";

      package = mkPackageOption pkgs "darcs" { };

      author = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "Fred Bloggs <fred@example.net>" ];
        description = ''
          If this list has a single entry, it will be used as the author
          when you record a patch. If there are multiple entries, Darcs
          will prompt you to choose one of them.
        '';
      };

      boring = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "^.idea$" ".iml$" "^.stack-work$" ];
        description = "File patterns to ignore";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    { home.packages = [ cfg.package ]; }

    (mkIf (cfg.author != [ ]) {
      home.file.".darcs/author".text =
        concatMapStrings (x: x + "\n") cfg.author;
    })

    (mkIf (cfg.boring != [ ]) {
      home.file.".darcs/boring".text =
        concatMapStrings (x: x + "\n") cfg.boring;
    })

  ]);
}
