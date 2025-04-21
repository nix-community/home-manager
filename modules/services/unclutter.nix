{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkOption
    types
    ;

  cfg = config.services.unclutter;

in
{
  options.services.unclutter = {

    enable = lib.mkEnableOption "unclutter";

    package = mkOption {
      description = "unclutter derivation to use.";
      type = types.package;
      default = pkgs.unclutter-xfixes;
      defaultText = lib.literalExpression "pkgs.unclutter-xfixes";
    };

    timeout = mkOption {
      description = "Number of seconds before the cursor is marked inactive.";
      type = types.int;
      default = 1;
    };

    threshold = mkOption {
      description = "Minimum number of pixels considered cursor movement.";
      type = types.int;
      default = 1;
    };

    extraOptions = mkOption {
      description = "More arguments to pass to the unclutter command.";
      type = types.listOf types.str;
      default = [ ];
      example = [
        "exclude-root"
        "ignore-scrolling"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.unclutter" pkgs lib.platforms.linux)
    ];

    systemd.user.services.unclutter = {
      Unit = {
        Description = "unclutter";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = ''
          ${cfg.package}/bin/unclutter \
            --timeout ${toString cfg.timeout} \
            --jitter ${toString (cfg.threshold - 1)} \
            ${lib.concatMapStrings (x: " --${x}") cfg.extraOptions}
        '';
        RestartSec = 3;
        Restart = "always";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
