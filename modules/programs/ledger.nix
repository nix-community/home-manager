{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.ledger;

in {
  meta.maintainers = [ maintainers.marsam ];

  options.programs.ledger = {
    enable = mkEnableOption "ledger, a double-entry accounting system";

    package = mkPackageOption pkgs "ledger" { };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = literalExpression ''
        --sort date
        --effective
        --date-format %Y-%m-%d
      '';
      description = ''
        Configuration written to <filename>$XDG_CONFIG_HOME/ledger/ledgerrc</filename>.
        See <link xlink:href="https://www.ledger-cli.org/3.0/doc/ledger3.html#Detailed-Option-Description"/>
        for explanation about possible values.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."ledger/ledgerrc" =
      mkIf (cfg.extraConfig != "") { text = cfg.extraConfig; };
  };
}
