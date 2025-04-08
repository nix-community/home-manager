{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;

  cfg = config.programs.mercurial;

  iniFormat = pkgs.formats.ini { };

in
{

  options = {
    programs.mercurial = {
      enable = lib.mkEnableOption "Mercurial";

      package = lib.mkPackageOption pkgs "mercurial" { };

      userName = mkOption {
        type = types.str;
        description = "Default user name to use.";
      };

      userEmail = mkOption {
        type = types.str;
        description = "Default user email to use.";
      };

      aliases = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Mercurial aliases to define.";
      };

      extraConfig = mkOption {
        type = types.either (types.attrsOf types.anything) types.lines;
        default = { };
        description = "Additional configuration to add.";
      };

      iniContent = mkOption {
        type = iniFormat.type;
        internal = true;
      };

      ignores = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "*~"
          "*.swp"
        ];
        description = "List of globs for files to be globally ignored.";
      };

      ignoresRegexp = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "^.*~$"
          "^.*\\.swp$"
        ];
        description = "List of regular expressions for files to be globally ignored.";
      };
    };
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = [ cfg.package ];

        programs.mercurial.iniContent.ui = {
          username = cfg.userName + " <" + cfg.userEmail + ">";
        };

        xdg.configFile."hg/hgrc".source = iniFormat.generate "hgrc" cfg.iniContent;
      }

      (mkIf (cfg.ignores != [ ] || cfg.ignoresRegexp != [ ]) {
        programs.mercurial.iniContent.ui.ignore = "${config.xdg.configHome}/hg/hgignore_global";

        xdg.configFile."hg/hgignore_global".text =
          ''
            syntax: glob
          ''
          + lib.concatStringsSep "\n" cfg.ignores
          + "\n"
          + ''
            syntax: regexp
          ''
          + lib.concatStringsSep "\n" cfg.ignoresRegexp
          + "\n";
      })

      (mkIf (cfg.aliases != { }) {
        programs.mercurial.iniContent.alias = cfg.aliases;
      })

      (mkIf (lib.isAttrs cfg.extraConfig) {
        programs.mercurial.iniContent = cfg.extraConfig;
      })

      (mkIf (lib.isString cfg.extraConfig) {
        xdg.configFile."hg/hgrc".text = cfg.extraConfig;
      })
    ]
  );
}
