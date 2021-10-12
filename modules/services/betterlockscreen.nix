{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.betterlockscreen;

in {
  meta.maintainers = with maintainers; [ sebtm ];

  options = {
    services.betterlockscreen = {
      enable = mkEnableOption "betterlockscreen, a screen-locker module";

      package = mkOption {
        type = types.package;
        default = pkgs.betterlockscreen;
        defaultText = literalExpression "pkgs.betterlockscreen";
        description = "Package providing <command>betterlockscreen</command>.";
      };

      arguments = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description =
          "List of arguments appended to <literal>./betterlockscreen --lock [args]</literal>";
      };

      inactiveInterval = mkOption {
        type = types.int;
        default = 10;
        description = ''
          Value used for <option>services.screen-locker.inactiveInterval</option>.
        '';
      };

    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.betterlockscreen" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    services.screen-locker = {
      enable = true;
      inactiveInterval = cfg.inactiveInterval;
      lockCmd = "${cfg.package}/bin/betterlockscreen --lock ${
          concatStringsSep " " cfg.arguments
        }";
    };
  };
}
