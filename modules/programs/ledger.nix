{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.ledger;
  package = pkgs.ledger;
  boolOption = value: name: if value == true then "--${name}" else "";
  valueOption = value: name: if value != null then "--${name} ${value}" else "";
in {
  meta.maintainers = [ maintainers.piperswe ];

  options.programs.ledger = {
    enable = mkEnableOption "ledger";
    package = mkOption {
      type = types.package;
      default = package;
      defaultText = literalExample "pkgs.ledger";
      description = ''
        The ledger package to use.
      '';
    };
    checkPayees = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable strict and pedantic checking for payees as well as
        accounts, commodities and tags. This only works in conjunction
        with strict or pedantic.
      '';
    };
    dayBreak = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Break up register report of timelog entries that span multiple
        days by day.
      '';
    };
    decimalComma = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Direct Ledger to parse journals using the European standard
        comma as a decimal separator, not the usual period. 
      '';
    };
    download = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Direct Ledger to download prices.
      '';
    };
    explicit = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Direct Ledger to require pre-declarations for entities (such as
        accounts, commodities and tags) rather than taking entities
        from cleared transactions as defined. This option is useful in
        combination with --strict or --pedantic.
      '';
    };
    file = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The location of the main ledger file.
      '';
    };
    inputDateFormat = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Specify the input date format for journal entries.
      '';
    };
    masterAccount = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Prepend all account names with the argument.
      '';
    };
    noAliases = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Ledger does not expand any aliases if this option is specified.
      '';
    };
    pedantic = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Accounts, tags or commodities not previously declared will cause errors.
      '';
    };
    permissive = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Quiet balance assertions.
      '';
    };
    priceDB = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Specify the location of the price entry data file.
      '';
    };
    priceExpectedFreshness = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        Set the expected freshness of price quotes, in minutes. That
        is, if the last known quote for any commodity is older than
        this value, and if --download is being used, then the Internet
        will be consulted again for a newer price. Otherwise, the old
        price is still considered to be fresh enough.
      '';
    };
    strict = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Ledger normally silently accepts any account or commodity in a
        posting, even if you have misspelled a commonly used one. The
        option --strict changes that behavior. While running with
        --strict, Ledger interprets all cleared transactions as
        correct, and if it encounters a new account or commodity (same
        as a misspelled commodity or account) it will issue a warning
        giving you the file and line number of the problem.
      '';
    };
    recursiveAliases = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Normally, ledger only expands aliases once. With this option,
        ledger tries to expand the result of alias expansion
        recursively, until no more expansions apply.
      '';
    };
    timeColon = mkOption {
      type = types.bool;
      default = false;
      description = ''
        The --time-colon option will display the value for a seconds
        based commodity as real hours and minutes.
      '';
    };
    valueExpr = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Set a global value expression annotation.
      '';
    };
    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Configuration lines to be appended to
        <filename>~/.ledgerrc</filename>. These are interpreted as
        command line options to be used on eachinvokation of ledger.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ package ];
    home.file.".ledgerrc".text = ''
      ${boolOption cfg.checkPayees "check-payees"}
      ${boolOption cfg.dayBreak "day-break"}
      ${boolOption cfg.decimalComma "decimal-comma"}
      ${boolOption cfg.download "download"}
      ${boolOption cfg.explicit "explicit"}
      ${valueOption cfg.file "file"}
      ${valueOption cfg.inputDateFormat "input-date-format"}
      ${valueOption cfg.masterAccount "master-account"}
      ${boolOption cfg.noAliases "no-aliases"}
      ${boolOption cfg.pedantic "pedantic"}
      ${boolOption cfg.permissive "permissive"}
      ${valueOption cfg.priceDB "price-db"}
      ${valueOption cfg.priceExpectedFreshness "price-exp"}
      ${boolOption cfg.strict "strict"}
      ${boolOption cfg.recursiveAliases "recursive-aliases"}
      ${boolOption cfg.timeColon "time-colon"}
      ${valueOption cfg.valueExpr "value-expr"}

      ${cfg.extraConfig}
    '';
  };
}
