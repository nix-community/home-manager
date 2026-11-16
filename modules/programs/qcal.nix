{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.qcal;

  jsonFormat = pkgs.formats.json { };

  qcalAccounts = lib.filterAttrs (_: account: account.qcal.enable) config.accounts.calendar.accounts;
in
{
  meta.maintainers = with lib.maintainers; [ antonmosich ];

  imports = [
    (lib.mkRenamedOptionModule
      [ "programs" "qcal" "timezone" ]
      [
        "programs"
        "qcal"
        "settings"
        "Timezone"
      ]
    )
    (lib.mkRenamedOptionModule
      [ "programs" "qcal" "defaultNumDays" ]
      [
        "programs"
        "qcal"
        "settings"
        "DefaultNumDays"
      ]
    )
  ];

  options = {
    programs.qcal = {
      enable = lib.mkEnableOption "qcal, a CLI calendar application";

      package = lib.mkPackageOption pkgs "qcal" { nullable = true; };

      settings = lib.mkOption {
        inherit (jsonFormat) type;
        default = { };
        example = lib.literalExpression ''
          {
            Timezone = "Europe/Vienna";
            DefaultNumDays = 7;
          }
        '';
        description = ''
          Configuration written to {file}`$XDG_CONFIG_HOME/qcal/config.json`.
          See <https://git.sr.ht/~psic4t/qcal> for supported keys.

          `Calendars` defaults to the enabled
          {option}`accounts.calendar.accounts.<name>.qcal` accounts. Setting
          it here replaces that list.

          Values are written to the Nix store. Use `PasswordCmd` instead of
          `Password` for calendar credentials.
        '';
      };
    };

    accounts.calendar.accounts = lib.mkOption {
      type =
        with lib.types;
        attrsOf (
          submodule (
            { config, ... }:
            {
              options.qcal = {
                enable = lib.mkEnableOption "qcal access";

                settings = lib.mkOption {
                  inherit (jsonFormat) type;
                  default = { };
                  example = lib.literalExpression ''
                    {
                      Url = "https://cal.example.com/work";
                      PasswordCmd = "pass show calendar/work";
                    }
                  '';
                  description = ''
                    Calendar entry written to `Calendars` in
                    {file}`$XDG_CONFIG_HOME/qcal/config.json`. `Url`, `Username`,
                    and `PasswordCmd` default to the account's `remote` options.

                    Values are written to the Nix store. Use `PasswordCmd` or
                    `remote.passwordCommand` instead of `Password`.
                  '';
                };
              };

              config.qcal.settings = lib.mkIf (config.remote != null) {
                Url = lib.mkIf (config.remote.url != null) (lib.mkDefault config.remote.url);
                Username = lib.mkIf (config.remote.userName != null) (lib.mkDefault config.remote.userName);
                PasswordCmd = lib.mkIf (config.remote.passwordCommand != null) (
                  lib.mkDefault (toString config.remote.passwordCommand)
                );
              };
            }
          )
        );
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    programs.qcal.settings = {
      Timezone = lib.mkDefault "Local";
      DefaultNumDays = lib.mkDefault 30;
      Calendars = lib.mkDefault (map (account: account.qcal.settings) (lib.attrValues qcalAccounts));
    };

    xdg.configFile."qcal/config.json".source = jsonFormat.generate "qcal.json" cfg.settings;
  };
}
