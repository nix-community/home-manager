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

        programs.sapling.iniContent.ui = {
          username = cfg.userName + " <" + cfg.userEmail + ">";
        };
      }

      (mkIf (!pkgs.stdenv.isDarwin) {
        xdg.configFile."sapling/sapling.conf".source = iniFormat.generate "sapling.conf" cfg.iniContent;
      })
      (mkIf (pkgs.stdenv.isDarwin) {
        home.file."Library/Preferences/sapling/sapling.conf".source =
          iniFormat.generate "sapling.conf" cfg.iniContent;
      })

      (mkIf (cfg.aliases != { }) {
        programs.sapling.iniContent.alias = cfg.aliases;
      })

      (mkIf (lib.isAttrs cfg.extraConfig) {
        programs.sapling.iniContent = cfg.extraConfig;
      })

      (mkIf (lib.isString cfg.extraConfig && !pkgs.stdenv.isDarwin) {
        xdg.configFile."sapling/sapling.conf".text = cfg.extraConfig;
      })
      (mkIf (lib.isString cfg.extraConfig && pkgs.stdenv.isDarwin) {
        home.file."Library/Preferences/sapling/sapling.conf".text = cfg.extraConfig;
      })
    ]
  );
}
