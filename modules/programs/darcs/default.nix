{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.darcs;
in
{
  meta.maintainers = with lib.maintainers; [ chris-martin ];

  options = {
    programs.darcs = {
      enable = lib.mkEnableOption "darcs";

      package = lib.mkPackageOption pkgs "darcs" { nullable = true; };

      author = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "Fred Bloggs <fred@example.net>" ];
        description = ''
          If this list has a single entry, it will be used as the author
          when you record a patch. If there are multiple entries, Darcs
          will prompt you to choose one of them.
        '';
      };

      boring = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "^.idea$"
          ".iml$"
          "^.stack-work$"
        ];
        description = "File patterns to ignore";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      { home.packages = lib.mkIf (cfg.package != null) [ cfg.package ]; }

      (lib.mkIf (cfg.author != [ ]) {
        home.file.".darcs/author".text = lib.concatMapStrings (x: x + "\n") cfg.author;
      })

      (lib.mkIf (cfg.boring != [ ]) {
        home.file.".darcs/boring".text = lib.concatMapStrings (x: x + "\n") cfg.boring;
      })

    ]
  );
}
