{ config, lib, pkgs, ... }:

with lib;

let
  inherit (lib.strings) toJSON;
  cfg = config.services.poweralertd;
  escapeSystemdExecArg = arg:
    let
      s = if isPath arg then
        "${arg}"
      else if isString arg then
        arg
      else if isInt arg || isFloat arg || isDerivation arg then
        toString arg
      else
        throw
        "escapeSystemdExecArg only allows strings, paths, numbers and derivations";
    in replaceStrings [ "%" "$" ] [ "%%" "$$" ] (toJSON s);
  escapeSystemdExecArgs = concatMapStringsSep " " escapeSystemdExecArg;
in {
  meta.maintainers = [ maintainers.thibautmarty ];

  options.services.poweralertd = {
    enable = mkEnableOption "the Upower-powered power alertd";

    extraArgs = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "-s" "-S" ];
      description = ''
        Extra command line arguments to pass to poweralertd.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.poweralertd" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.poweralertd = {
      Unit = {
        Description = "UPower-powered power alerter";
        Documentation = "man:poweralertd(1)";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.poweralertd}/bin/poweralertd ${
            escapeSystemdExecArgs cfg.extraArgs
          }";
        Restart = "always";
      };
    };
  };
}
