{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;

  cfg = config.programs.khard;

  accounts = lib.filterAttrs (_: acc: acc.khard.enable) config.accounts.contact.accounts;

  renderSettings =
    with lib.generators;
    toINI {
      mkKeyValue = mkKeyValueDefault rec {
        mkValueString =
          v:
          if lib.isList v then
            lib.concatStringsSep ", " v
          else if lib.isBool v then
            if v then "yes" else "no"
          else
            v;
      } "=";
    };
in
{

  meta.maintainers = [
    lib.hm.maintainers.olmokramer
    lib.maintainers.antonmosich
  ];

  options = {
    programs.khard = {
      enable = lib.mkEnableOption "Khard: an address book for the Unix console";

      package = lib.mkPackageOption pkgs "khard" { };

      settings = lib.mkOption {
        type =
          with lib.types;
          submodule {
            freeformType =
              let
                primOrList = oneOf [
                  bool
                  str
                  (listOf str)
                ];
              in
              attrsOf (attrsOf primOrList);

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
      type = types.attrsOf (
        types.submodule {
          imports = [
            (lib.mkRenamedOptionModule [ "khard" "defaultCollection" ] [ "khard" "addressbooks" ])
          ];
          options.khard.enable = lib.mkEnableOption "khard access";
          options.khard.addressbooks = lib.mkOption {
            type = types.coercedTo types.str lib.toList (types.listOf types.str);
            default = [ "" ];
            description = ''
              If provided, each item on this list will generate an
              entry on khard configuration file as a separate addressbook
              (vdir).

              This is used for hardcoding sub-directories under the local
              storage path
              (accounts.contact.accounts.<name>.local.path) for khard. The
              default value will set the aforementioned path as a single vdir.
            '';
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."khard/khard.conf".text =
      let
        makePath =
          baseDir: subDir:
          builtins.toString (
            /.
            + lib.concatStringsSep "/" [
              baseDir
              subDir
            ]
          );
        makeName = accName: abookName: accName + lib.optionalString (abookName != "") "-${abookName}";
        makeEntry = anAccount: anAbook: ''
          [[${makeName anAccount.name anAbook}]]
          path = ${makePath anAccount.local.path anAbook}
        '';
      in
      ''
        [addressbooks]
        ${lib.concatMapStringsSep "\n" (
          acc: lib.concatMapStringsSep "\n" (makeEntry acc) acc.khard.addressbooks
        ) (lib.attrValues accounts)}

        ${renderSettings cfg.settings}
      '';
  };
}
