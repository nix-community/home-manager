{ config, lib, pkgs, ... }:

with lib;

let
 
  config = cfg.accounts.contact;

#  contactOpts = { name, config, ... }: {
#    options = {
#      name = mkOption {
#        type = types.str;
#        readOnly = true;
#        description = ''
#          Unique identifier of the contact. This is set to the
#          attribute name of the contact configuration.
#        '';
#      };
#    };
#
#    config = mkMerge [ { name = name; } ];
#  };

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
#        contactOpts
        (import ../programs/vdirsyncer-accounts.nix)
      ]);
      default = {};
      description = "List of contacts.";
    };
  };
}
