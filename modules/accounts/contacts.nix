{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.accounts.contact;

  contactOpts = { name, config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        readOnly = true;
        description = ''
          Unique identifier of the contact. This is set to the
          attribute name of the contact configuration.
        '';
      };
    };

    config = mkMerge [
      { name = name; }

      # infinite recursion
      # (mkIf (config.khal.enable && isNull config.khal.type) {
      #   khal.type = "birthdays" ;
      # })
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
    assertions =
      map (a:
          {
            assertion = a.khal.type == "birthdays";
            message =
              a.name
              + " is a contact account so type must be birthdays";
            })
            (filter (a: a.khal.enable)
            (attrValues cfg.accounts));
  };
}
