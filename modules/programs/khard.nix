{ config, lib, pkgs, ... }:
let
  cfg = config.programs.khard;

  accounts =
    lib.filterAttrs (_: acc: acc.khard.enable) config.accounts.contact.accounts;

  renderSettings = with lib.generators;
    toINI {
      mkKeyValue = mkKeyValueDefault rec {
        mkValueString = v:
          if lib.isList v then
            lib.concatStringsSep ", " v
          else if lib.isBool v then
            if v then "yes" else "no"
          else
            v;
      } "=";
    };
in {
  meta.maintainers =
    [ lib.hm.maintainers.olmokramer lib.maintainers.antonmosich ];

  options = {
    programs.khard = {
      enable = lib.mkEnableOption "Khard: an address book for the Unix console";

      settings = lib.mkOption {
        type = with lib.types;
          submodule {
            freeformType = let primOrList = oneOf [ bool str (listOf str) ];
            in attrsOf (attrsOf primOrList);

            options.general.default_action = lib.mkOption {
              type = str;
              default = "list";
              description = "The default action to execute.";
            };
          };
        default = { };
        description = ''
          Khard settings. See
          <https://khard.readthedocs.io/en/latest/#configuration>
          for more information.
        '';
        example = lib.literalExpression ''
          {
            general = {
              default_action = "list";
              editor = ["vim" "-i" "NONE"];
            };

            "contact table" = {
              display = "formatted_name";
              preferred_phone_number_type = ["pref" "cell" "home"];
              preferred_email_address_type = ["pref" "work" "home"];
            };

            vcard = {
              private_objects = ["Jabber" "Skype" "Twitter"];
            };
          }
        '';
      };
    };

    accounts.contact.accounts = lib.mkOption {
      type = with lib.types;
        attrsOf (submodule {
          options.khard.enable = lib.mkEnableOption "khard access";
        });
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.khard ];

    xdg.configFile."khard/khard.conf".text = ''
      [addressbooks]
      ${lib.concatMapStringsSep "\n" (acc: ''
        [[${acc.name}]]
        path = ${acc.local.path}
      '') (lib.attrValues accounts)}

      ${renderSettings cfg.settings}
    '';
  };
}
