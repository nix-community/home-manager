{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.programs.man;
in
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "programs" "man" "extraConfig" ]
      [ "programs" "man" "man-db" "extraConfig" ]
    )
    ./man-db.nix
    ./mandoc.nix
  ];

  options = {
    programs.man = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to enable manual pages and the {command}`man`
          command. This also includes "man" outputs of all
          `home.packages`.
        '';
      };

      package = mkOption {
        type = with types; nullOr package;
        default =
          if pkgs.stdenv.isDarwin && lib.versionAtLeast config.home.stateVersion "26.05" then
            null
          else if cfg.man-db.enable then
            pkgs.man
          else if cfg.mandoc.enable then
            pkgs.mandoc
          else
            null;
        defaultText = lib.literalExpression ''
          if pkgs.stdenv.isDarwin && lib.versionAtLeast config.home.stateVersion "26.05" then
            null
          else if cfg.man-db.enable then
            pkgs.man
          else if cfg.mandoc.enable then
            pkgs.mandoc
          else
            null;
        '';
        description = "The {command}`man` package to use.";
      };

      generateCaches = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to generate the manual page index caches using
          {manpage}`mandb(8)`. This allows searching for a page or
          keyword using utilities like {manpage}`apropos(1)`.

          This feature is disabled by default because it slows down
          building. If you don't mind waiting a few more seconds when
          Home Manager builds a new generation, you may safely enable
          this option.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = lib.optional (
      cfg.generateCaches && cfg.package == null
    ) "programs.man.generateCaches has no effect when programs.man.package is null";

    assertions = [
      {
        assertion = !(cfg.mandoc.enable && cfg.man-db.enable);
        message = ''
          man-db and mandoc can't be used as the man page viewer at the same time!
        '';
      }
    ];

    home.packages = lib.optional (cfg.package != null) cfg.package;
    home.extraOutputsToInstall = [ "man" ];
  };
}
