{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.git;

  signModule = types.submodule {
    options = {
      key = mkOption {
        type = types.str;
        description = "The default GPG signing key fingerprint.";
      };

      signByDefault = mkOption {
        type = types.bool;
        default = false;
        description = "Whether commits should be signed by default.";
      };

      gpgPath = mkOption {
        type = types.str;
        default = "${pkgs.gnupg}/bin/gpg2";
        defaultText = "\${pkgs.gnupg}/bin/gpg2";
        description = "Path to GnuPG binary to use.";
      };
    };
  };

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.git = {
      enable = mkEnableOption "Git";

      package = mkOption {
        type = types.package;
        default = pkgs.git;
        defaultText = "pkgs.git";
        description = "Git package to install.";
      };

      userName = mkOption {
        type = types.str;
        description = "Default user name to use.";
      };

      userEmail = mkOption {
        type = types.str;
        description = "Default user email to use.";
      };

      aliases = mkOption {
        type = types.attrs;
        default = {};
        description = "Git aliases to define.";
      };

      signing = mkOption {
        type = types.nullOr signModule;
        default = null;
        description = "Options related to signing commits using GnuPG.";
      };

      extraConfig = mkOption {
        type = types.either types.attrs types.lines;
        default = {};
        description = "Additional configuration to add.";
      };

      iniContent = mkOption {
        type = types.attrsOf types.attrs;
        internal = true;
      };

      ignores = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [ "*~" "*.swp" ];
        description = "List of paths that should be globally ignored.";
      };
    };
  };

  config = mkIf cfg.enable (
    mkMerge [
      {
        home.packages = [ cfg.package ];

        programs.git.iniContent.user = {
          name = cfg.userName;
          email = cfg.userEmail;
        };

        xdg.configFile = {
          "git/config".text = generators.toINI {} cfg.iniContent;

          "git/ignore" = mkIf (cfg.ignores != []) {
            text = concatStringsSep "\n" cfg.ignores + "\n";
          };
        };
      }

      (mkIf (cfg.signing != null) {
        programs.git.iniContent = {
          user.signingKey = cfg.signing.key;
          commit.gpgsign = cfg.signing.signByDefault;
          gpg.program = cfg.signing.gpgPath;
        };
      })

      (mkIf (cfg.aliases != {}) {
        programs.git.iniContent.alias = cfg.aliases;
      })

      (mkIf (lib.isAttrs cfg.extraConfig) {
        programs.git.iniContent = cfg.extraConfig;
      })

      (mkIf (lib.isString cfg.extraConfig) {
        xdg.configFile."git/config".text = cfg.extraConfig;
      })
    ]
  );
}
