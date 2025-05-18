{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.betterlockscreen;
in
{
  meta.maintainers = with lib.maintainers; [ sebtm ];

  options = {
    services.betterlockscreen = {
      enable = lib.mkEnableOption "betterlockscreen, a screen-locker module";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.betterlockscreen;
        defaultText = lib.literalExpression "pkgs.betterlockscreen";
        description = "Package providing {command}`betterlockscreen`.";
      };

      arguments = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of arguments appended to `./betterlockscreen --lock [args]`";
      };

      inactiveInterval = lib.mkOption {
        type = lib.types.int;
        default = 10;
        description = ''
          Value used for {option}`services.screen-locker.inactiveInterval`.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.betterlockscreen" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    services.screen-locker = {
      enable = true;
      inactiveInterval = cfg.inactiveInterval;
      lockCmd = "${cfg.package}/bin/betterlockscreen --lock ${lib.concatStringsSep " " cfg.arguments}";
    };
  };
}
