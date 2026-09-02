{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.qcal;
  jsonFormat = pkgs.formats.json { };

  calendarSettings = {
    freeformType = jsonFormat.type;
  };

  settingsModule = {
    freeformType = jsonFormat.type;
    options = {
      Timezone = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "Local";
        example = "Europe/Vienna";
        description = "Timezone to display calendar entries in";
      };
      DefaultNumDays = lib.mkOption {
        type = lib.types.ints.positive;
        default = 30;
        description = "Default number of days to show calendar entries for";
      };
      Calendars = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule calendarSettings);
        default = [ ];
        description = "Calendar entries to display";
      };
    };
  };

  qcalAccounts = lib.filterAttrs (_: account: account.qcal.enable) config.accounts.calendar.accounts;

  passwordKeys =
    settingsValue:
    lib.filter (
      name:
      lib.replaceStrings [ "ſ" ] [ "s" ] (lib.toLower name) == "password"
      && settingsValue.${name} != null
      && settingsValue.${name} != ""
    ) (lib.attrNames settingsValue);
in
{
  meta.maintainers = with lib.maintainers; [ antonmosich ];

  imports = [
    (lib.doRename {
      from = [
        "programs"
        "qcal"
        "timezone"
      ];
      to = [
        "programs"
        "qcal"
        "settings"
        "Timezone"
      ];
      visible = false;
      warn = true;
      use = x: x;
      condition = cfg.enable;
    })
    (lib.doRename {
      from = [
        "programs"
        "qcal"
        "defaultNumDays"
      ];
      to = [
        "programs"
        "qcal"
        "settings"
        "DefaultNumDays"
      ];
      visible = false;
      warn = true;
      use = x: x;
      condition = cfg.enable;
    })
  ];

  options = {
    programs.qcal = {
      enable = lib.mkEnableOption "qcal, a CLI calendar application";
      package = lib.mkPackageOption pkgs "qcal" { nullable = true; };
      settings = lib.mkOption {
        type = lib.types.submodule settingsModule;
        default = { };
        description = ''
          Settings for qcal's JSON configuration file. Qcal treats `Password`
          keys in `Calendars` entries case-insensitively. These values are
          written to the Nix store. Use `PasswordCmd` to read the credential at
          runtime.
        '';
      };
    };

    accounts.calendar.accounts = lib.mkOption {
      type =
        with lib.types;
        attrsOf (
          submodule (
            { config, ... }: {
              options.qcal = {
                enable = lib.mkEnableOption "qcal access";
                settings = lib.mkOption {
                  type = lib.types.submodule calendarSettings;
                  default = { };
                  description = ''
                    Settings for this qcal calendar account. Qcal treats `Password`
                    keys case-insensitively. These values are written to the Nix
                    store. Use `PasswordCmd` or `remote.passwordCommand` to read the
                    credential at runtime.
                  '';
                };
              };

              config.qcal.settings = {
                Url = lib.mkIf (config.remote != null && config.remote.url != null) (
                  lib.mkDefault config.remote.url
                );
                Username = lib.mkIf (config.remote != null && config.remote.userName != null) (
                  lib.mkDefault config.remote.userName
                );
                PasswordCmd = lib.mkIf (config.remote != null && config.remote.passwordCommand != null) (
                  lib.mkDefault (toString config.remote.passwordCommand)
                );
              };
            }
          )
        );
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = lib.concatLists (
      lib.imap0 (
        index: calendar:
        map (
          name:
          "qcal: `programs.qcal.settings.Calendars[${toString index}].${name}` is written to the Nix store. Use `PasswordCmd` to read the credential at runtime."
        ) (passwordKeys calendar)
      ) cfg.settings.Calendars
    );

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
    programs.qcal.settings.Calendars = lib.mkDefault (
      map (account: account.qcal.settings) (lib.attrValues qcalAccounts)
    );
    xdg.configFile."qcal/config.json".source = jsonFormat.generate "qcal.json" cfg.settings;
  };
}
