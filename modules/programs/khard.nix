{ lib, config, pkgs, ... }:
let
  cfg = config.programs.khard;

  khardAccounts = (lib.filterAttrs (_: a: a.khard.enable == true)
    config.accounts.contact.accounts);

  genStr = _: entry:
    lib.concatStringsSep "\n" [
      "[[${entry.name}]]"
      "path=${entry.local.path}"
    ];

  mkKeyValue = lib.generators.mkKeyValueDefault {
    mkValueString = (v:
      with builtins;
      if lib.isDerivation v then
        toString v
        # we default to not quoting strings
      else if isString v then
        v
        # isString returns "1", which is not a good default
      else if true == v then
        "yes"
        # here it returns to "", which is even less of a good default
      else if false == v then
        "no"
      else if null == v then
        "null"
      else if isList v then
        lib.concatStringsSep ", " v
      else
        "");
  } "=";
in {
  meta.maintainers = with lib.maintainers; [ antonmosich ];

  options = {
    programs.khard = {
      enable = lib.mkEnableOption "khard, a CLI vcard client";

      defaultAction = lib.mkOption {
        type = lib.types.enum [
          "add-email"
          "addressbooks"
          "birthdays"
          "copy"
          "edit"
          "email"
          "filename"
          "list"
          "merge"
          "move"
          "new"
          "phone"
          "postaddress"
          "remove"
          "show"
          "template"
        ];
        default = "list";
        description = "The default action to execute";
      };

      settings = lib.mkOption {
        type = with lib.types;
          attrsOf (attrsOf (oneOf [ bool str (listOf str) ]));
        default = { };
        example = {
          general.editor = [ "vim" "-i" "NONE" ];
          "contact table" = {
            display = "first_name";
            show_nicknames = true;
            show_uids = false;
          };
        };
        description =
          "Additional settings for khard. Other options take precedence.";
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

    xdg.configFile."khard/khard.conf".text = lib.concatStringsSep "\n"
      ([ "[addressbooks]" ] ++ (lib.mapAttrsToList genStr khardAccounts) ++ [
        (lib.generators.toINI { inherit mkKeyValue; }
          (lib.recursiveUpdate cfg.settings {
            general = { default_action = cfg.defaultAction; };
          }))
      ]);
  };
}
