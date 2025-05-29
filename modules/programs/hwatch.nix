{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkIf
    mkOption
    types
    ;
  cfg = config.programs.hwatch;
in
{
  meta.maintainers = with lib.hm.maintainers; [
    Aehmlo
  ];

  options.programs.hwatch = {
    enable = lib.mkEnableOption ''
      hwatch, a modern alternative to the {command}`watch` command
    '';

    package = lib.mkPackageOption pkgs "hwatch" { nullable = true; };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "--exec"
        "--precise"
      ];
      description = ''
        Extra command-line arguments to pass to {command}`hwatch`.
        These will be used to populate the {env}`HWATCH` environment variable.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    home.sessionVariables = mkIf (cfg.extraArgs != [ ]) {
      HWATCH = lib.concatMapStringsSep " " lib.escapeShellArg cfg.extraArgs;
    };
  };

}
