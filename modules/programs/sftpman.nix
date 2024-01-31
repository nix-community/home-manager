{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.sftpman;

  jsonFormat = pkgs.formats.json { };

  mountOpts = { config, name, ... }: {
    options = {
      host = mkOption {
        type = types.str;
        description = "The host to connect to.";
      };

      port = mkOption {
        type = types.port;
        default = 22;
        description = "The port to connect to.";
      };

      user = mkOption {
        type = types.str;
        description = "The username to authenticate with.";
      };

      mountOptions = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Options to pass to sshfs.";
      };

      mountPoint = mkOption {
        type = types.str;
        description = "The remote path to mount.";
      };

      authType = mkOption {
        type = types.enum [
          "password"
          "publickey"
          "hostbased"
          "keyboard-interactive"
          "gssapi-with-mic"
        ];
        default = "publickey";
        description = "The authentication method to use.";
      };

      sshKey = mkOption {
        type = types.nullOr types.str;
        default = cfg.defaultSshKey;
        defaultText =
          lib.literalExpression "config.programs.sftpman.defaultSshKey";
        description = ''
          Path to the SSH key to use for authentication.
          Only applies if authMethod is `publickey`.
        '';
      };

      beforeMount = mkOption {
        type = types.str;
        default = "true";
        description = "Command to run before mounting.";
      };
    };
  };
in {
  meta.maintainers = with maintainers; [ fugi ];

  options.programs.sftpman = {
    enable = mkEnableOption
      "sftpman, an application that handles sshfs/sftp file systems mounting";

    package = mkPackageOption pkgs "sftpman" { };

    defaultSshKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description =
        "Path to the SSH key to be used by default. Can be overridden per host.";
    };

    mounts = mkOption {
      type = types.attrsOf (types.submodule mountOpts);
      default = { };
      description = ''
        The sshfs mount configurations written to
        {file}`$XDG_CONFIG_HOME/sftpman/mounts/`.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (let
        hasMissingKey = _: mount:
          mount.authType == "publickey" && mount.sshKey == null;
        mountsWithMissingKey = attrNames (filterAttrs hasMissingKey cfg.mounts);
        mountsWithMissingKeyStr = concatStringsSep ", " mountsWithMissingKey;
      in {
        assertion = mountsWithMissingKey == [ ];
        message = ''
          sftpman mounts using authentication type "publickey" but missing 'sshKey': ${mountsWithMissingKeyStr}
        '';
      })
    ];

    home.packages = [ cfg.package ];

    xdg.configFile = mapAttrs' (name: value:
      nameValuePair "sftpman/mounts/${name}.json" {
        source =
          jsonFormat.generate "sftpman-${name}.json" (value // { id = name; });
      }) cfg.mounts;
  };
}
