{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;

  cfg = config.programs.sapling;

  iniFormat = pkgs.formats.ini { };

  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then "Library/Preferences" else config.xdg.configHome;

in
{
  meta.maintainers = [ lib.maintainers.pbar ];

  options = {
    programs.sapling = {
      enable = lib.mkEnableOption "Sapling";

      package = lib.mkPackageOption pkgs "sapling" { nullable = true; };

      userName = mkOption {
        type = types.str;
        description = "Default user name to use.";
      };

      userEmail = mkOption {
        type = types.str;
        description = "Default user email to use.";
      };

      aliases = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Sapling aliases to define.";
      };

      extraConfig = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Additional configuration to add.";
      };

      iniContent = mkOption {
        type = iniFormat.type;
        internal = true;
      };
    };
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

        programs.sapling.iniContent = {
          alias = mkIf (cfg.aliases != { }) cfg.aliases;
          ui.username = cfg.userName + " <" + cfg.userEmail + ">";
        };

        home.file."${configDir}/sapling/sapling.conf" = mkIf (cfg.iniContent != { }) {
          source = iniFormat.generate "sapling.conf" cfg.iniContent;
        };
      }

      (mkIf (lib.isAttrs cfg.extraConfig) {
        programs.sapling.iniContent = cfg.extraConfig;
      })

      (mkIf (lib.isString cfg.extraConfig) {
        home.file."${configDir}/sapling/sapling.conf".text = cfg.extraConfig;
      })
    ]
  );
}
