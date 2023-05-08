{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.sapling;

  iniFormat = pkgs.formats.ini { };

in {
  meta.maintainers = [ maintainers.pbar ];

  options = {
    programs.sapling = {
      enable = mkEnableOption "Sapling";

      package = mkPackageOption pkgs "sapling" { };

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

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ cfg.package ];

      programs.sapling.iniContent.ui = {
        username = cfg.userName + " <" + cfg.userEmail + ">";
      };
    }

    (mkIf (!pkgs.stdenv.isDarwin) {
      xdg.configFile."sapling/sapling.conf".source =
        iniFormat.generate "sapling.conf" cfg.iniContent;
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
      home.file."Library/Preferences/sapling/sapling.conf".text =
        cfg.extraConfig;
    })
  ]);
}
