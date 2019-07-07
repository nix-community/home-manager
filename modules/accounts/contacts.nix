{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.accounts.contact;

  localModule = name: types.submodule {
    options = {
      path = mkOption {
        type = types.str;
        default = "${cfg.basePath}/${name}";
        description = "The path of the storage.";
      };

      type = mkOption {
        type = types.enum [ "filesystem" "singlefile" ];
        description = "The type of the storage.";
      };

      fileExt = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The file extension to use.";
      };

      encoding = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          File encoding for items, both content and file name.
          Defaults to UTF-8.
        '';
      };
    };
  };

  remoteModule = types.submodule {
    options = {
      type = mkOption {
        type = types.enum [ "carddav" "http" "google_contacts" ];
        description = "The type of the storage.";
      };

      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The url of the storage.";
      };

      userName = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "User name for authentication.";
      };

      userNameCommand = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        example = [ "~/get-username.sh" ];
        description = ''
          A command that prints the user name to standard
          output.
        '';
      };

      passwordCommand = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        example = [ "pass" "caldav" ];
        description = ''
          A command that prints the password to standard
          output.
        '';
      };
    };
  };

  contactOpts = { name, config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        readOnly = true;
        description = ''
          Unique identifier of the contact account. This is set to the
          attribute name of the contact configuration.
        '';
      };

      local = mkOption {
        type = types.nullOr (localModule name);
        default = null;
        description = ''
          Local configuration for the contacts.
        '';
      };

      remote = mkOption {
        type = types.nullOr remoteModule;
        default = null;
        description = ''
          Remote configuration for the contacts.
        '';
      };
    };

    config = mkMerge [
      {
        name = name;
      }
    ];
  };

in

{
  options.accounts.contact = {
    basePath = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.contacts/";
      defaultText = "$HOME/.contacts";
      description = ''
        The base directory in which to save contacts.
      '';
    };

    accounts = mkOption {
      type = types.attrsOf (types.submodule [
        contactOpts
        (import ../programs/vdirsyncer-accounts.nix)
        (import ../programs/khal-accounts.nix)
      ]);
      default = {};
      description = "List of contacts.";
    };
  };
  config = mkIf (cfg.accounts != {}) {
  };
}
