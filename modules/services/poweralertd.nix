{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.strings) toJSON;

  cfg = config.services.poweralertd;
  escapeSystemdExecArg =
    arg:
    let
      s =
        if lib.isPath arg then
          "${arg}"
        else if lib.isString arg then
          arg
        else if lib.isInt arg || lib.isFloat arg || lib.isDerivation arg then
          toString arg
        else
          throw "escapeSystemdExecArg only allows strings, paths, numbers and derivations";
    in
    lib.replaceStrings [ "%" "$" ] [ "%%" "$$" ] (toJSON s);
  escapeSystemdExecArgs = lib.concatMapStringsSep " " escapeSystemdExecArg;
in
{
  meta.maintainers = [ lib.maintainers.thibautmarty ];

  options.services.poweralertd = {
    enable = lib.mkEnableOption "the Upower-powered power alertd";

    package = lib.mkPackageOption pkgs "poweralertd" { };

    extraArgs = lib.mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [
        "-s"
        "-S"
      ];
      description = ''
        Extra command line arguments to pass to poweralertd.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.poweralertd" pkgs lib.platforms.linux)
    ];

    systemd.user.services.poweralertd = {
      Unit = {
        Description = "UPower-powered power alerter";
        Documentation = "man:poweralertd(1)";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe cfg.package} ${escapeSystemdExecArgs cfg.extraArgs}";
        Restart = "always";
      };
    };
  };
}
