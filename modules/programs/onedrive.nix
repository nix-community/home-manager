{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    types
    concatStringsSep
    mapAttrsToList
    ;

  cfg = config.programs.onedrive;

  generateConfig = lib.generators.toKeyValue {
    mkKeyValue = name: value: ''${name} = "${value}"'';
  };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.onedrive = {
    enable = mkEnableOption "onedrive";
    package = mkPackageOption pkgs "onedrive" { nullable = true; };
    settings = mkOption {
      type = with types; attrsOf str;
      default = { };
      example = ''
        {
          check_nomount = "false";
          check_nosync = "false";
          classify_as_big_delete = "1000";
          cleanup_local_files = "false";
          disable_notifications = "false";
          no_remote_delete = "false";
          rate_limit = "0";
          resync = "false";
          skip_dotfiles = "false";
        }
      '';
      description = ''
        Configuration settings for Onedrive. All available options can be
        found at <https://github.com/abraunegg/onedrive/blob/master/config>.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.onedrive" pkgs lib.platforms.linux)
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = mkIf (cfg.settings != { }) {
      "onedrive/config".text = generateConfig cfg.settings;
    };
  };
}
