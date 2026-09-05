{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.moor;
in
{
  meta.maintainers = with lib.maintainers; [ wini ];

  options.programs.moor = {
    enable = lib.mkEnableOption "moor, a modern pager for humans";

    package = lib.mkPackageOption pkgs "moor" { };

    options = lib.mkOption {
      type =
        with lib.types;
        let
          scalar = oneOf [
            bool
            int
            str
          ];
          attrs = attrsOf (either scalar (listOf scalar));
        in
        coercedTo attrs (lib.cli.toCommandLineGNU { }) (listOf str);
      default = [ ];
      description = "Options to be set via {env}`$MOOR`.";
      example = {
        no-linenumbers = true;
        no-statusbar = true;
        quit-if-one-screen = true;
      };
    };

    enableJujutsuIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable Jujutsu integration for moor.

        When enabled, moor will be configured as Jujutsu's pager.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [ cfg.package ];
      home.sessionVariables = {
        PAGER = lib.mkDefault (lib.getExe cfg.package);
        MOOR = lib.mkIf (cfg.options != [ ]) (lib.concatStringsSep " " cfg.options);
      };
    })

    (lib.mkIf (cfg.enable && cfg.enableJujutsuIntegration) {
      programs.jujutsu.settings.ui.pager = lib.getExe cfg.package;
    })
  ];
}
