{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.git;

  toINI = (import ../lib/generators.nix).toINI {};

  signModule = types.submodule (
    { ... }: {
      options = {
        key = mkOption {
          type = types.str;
          default = null;
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
    }
  );

in

{
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
        type = types.lines;
        default = null;
        description = "Additional configuration to add.";
      };
    };
  };

  config = mkIf cfg.enable (
    let
      ini = {
        user = {
          name = cfg.userName;
          email = cfg.userEmail;
        } // optionalAttrs (cfg.signing != null) {
          signingKey = cfg.signing.key;
        };
      } // optionalAttrs (cfg.signing != null) {
        commit.gpgSign = cfg.signing.signByDefault;
        gpg.program = cfg.signing.gpgPath;
      } // optionalAttrs (cfg.aliases != {}) {
        alias = cfg.aliases;
      };
    in
      {
        home.packages = [ cfg.package ];

        home.file.".gitconfig".text = toINI ini + "\n" + cfg.extraConfig;
      }
  );
}
