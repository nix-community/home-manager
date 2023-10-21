{ config, lib, pkgs, ... }:

let

  cfg = config.programs.qcal;

  qcalAccounts = lib.attrValues
    (lib.filterAttrs (_: a: a.qcal.enable) config.accounts.calendar.accounts);

  rename = oldname:
    builtins.getAttr oldname {
      url = "Url";
      userName = "Username";
      passwordCommand = "PasswordCmd";
    };

  filteredAccounts = let
    mkAccount = account:
      lib.filterAttrs (_: v: v != null) (with account.remote; {
        Url = url;
        Username = if userName == null then null else userName;
        PasswordCmd =
          if passwordCommand == null then null else toString passwordCommand;
      });
  in map mkAccount qcalAccounts;

in {
  meta.maintainers = with lib.maintainers; [ antonmosich ];

  options = {
    programs.qcal = {
      enable = lib.mkEnableOption "qcal, a CLI calendar application";

      timezone = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "Local";
        example = "Europe/Vienna";
        description = "Timezone to display calendar entries in";
      };

      defaultNumDays = lib.mkOption {
        type = lib.types.ints.positive;
        default = 30;
        description = "Default number of days to show calendar entries for";
      };
    };

    accounts.calendar.accounts = lib.mkOption {
      type = with lib.types;
        attrsOf
        (submodule { options.qcal.enable = lib.mkEnableOption "qcal access"; });
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.qcal ];

    xdg.configFile."qcal/config.json".source =
      let jsonFormat = pkgs.formats.json { };
      in jsonFormat.generate "qcal.json" {
        DefaultNumDays = cfg.defaultNumDays;
        Timezone = cfg.timezone;
        Calendars = filteredAccounts;
      };
  };
}
