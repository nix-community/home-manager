{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.ledger;

  cfgText = generators.toKeyValue {
    mkKeyValue = key: value:
      if isBool value then
        optionalString value "--${key}"
      else
        "--${key} ${toString value}";
    listsAsDuplicateKeys = true;
  } cfg.settings;

in {
  meta.maintainers = [ ];

  options.programs.ledger = {
    enable = mkEnableOption "ledger, a double-entry accounting system";

    package = mkPackageOption pkgs "ledger" { };

    settings = mkOption {
      type = with types; attrsOf (oneOf [ bool int str (listOf str) ]);
      default = { };
      example = {
        sort = "date";
        date-format = "%Y-%m-%d";
        strict = true;
        file = [
          "~/finances/journal.ledger"
          "~/finances/assets.ledger"
          "~/finances/income.ledger"
        ];
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/ledger/ledgerrc`.
        See <https://www.ledger-cli.org/3.0/doc/ledger3.html#Detailed-Option-Description>
        for explanation about possible values.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = literalExpression ''
        --sort date
        --effective
        --date-format %Y-%m-%d
      '';
      description = ''
        Extra configuration to add to
        {file}`$XDG_CONFIG_HOME/ledger/ledgerrc`.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."ledger/ledgerrc" =
      mkIf (cfg.settings != { } || cfg.extraConfig != "") {
        text = cfgText + cfg.extraConfig;
      };
  };
}
