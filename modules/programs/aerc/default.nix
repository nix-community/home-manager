{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrsets
    generators
    literalExpression
    mapAttrs
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.aerc;

  primitive =
    with types;
    ((type: either type (listOf type)) (
      nullOr (oneOf [
        str
        int
        bool
        float
      ])
    ))
    // {
      description = "values (null, bool, int, string, or float) or a list of values, that will be joined with a comma";
    };

  confSection = types.attrsOf primitive;

  confSections = types.attrsOf (types.either types.lines confSection);

  sectionsOrLines = types.either types.lines confSections;

  accounts = import ./accounts.nix {
    inherit
      config
      pkgs
      lib
      confSection
      confSections
      ;
  };

  aerc-accounts = attrsets.filterAttrs (
    _: v: v.enable && v.aerc.enable
  ) config.accounts.email.accounts;

  configDir =
    if (pkgs.stdenv.isDarwin && !config.xdg.enable) then
      "Library/Preferences/aerc"
    else
      "${config.xdg.configHome}/aerc";

in
{
  meta.maintainers = with lib.hm.maintainers; [ lukasngl ];

  options.accounts.email.accounts = accounts.type;

  options.programs.aerc = {

    enable = lib.mkEnableOption "aerc";

    package = lib.mkPackageOption pkgs "aerc" { nullable = true; };

    extraAccounts = mkOption {
      type = sectionsOrLines;
      default = { };
      example = literalExpression ''{ Work = { source = "maildir://~/Maildir/work"; }; }'';
      description = ''
        Extra lines added to {file}`$HOME/.config/aerc/accounts.conf`.

        See {manpage}`aerc-config(5)`.
      '';
    };

    extraBinds = mkOption {
      type = sectionsOrLines;
      default = { };
      example = literalExpression ''{ messages = { q = ":quit<Enter>"; }; }'';
      description = ''
        Extra lines added to {file}`$HOME/.config/aerc/binds.conf`.
        Global keybindings can be set in the `global` section.

        See {manpage}`aerc-config(5)`.
      '';
    };

    extraConfig = mkOption {
      type = sectionsOrLines;
      default = { };
      example = literalExpression ''{ ui = { sort = "-r date"; }; }'';
      description = ''
        Extra lines added to {file}`$HOME/.config/aerc/aerc.conf`.

        See {manpage}`aerc-config(5)`.
      '';
    };

    stylesets = mkOption {
      type = with types; attrsOf (either confSection lines);
      default = { };
      example = literalExpression ''
        { default = { ui = { "tab.selected.reverse" = toggle; }; }; };
      '';
      description = ''
        Stylesets added to {file}`$HOME/.config/aerc/stylesets/`.

        See {manpage}`aerc-stylesets(7)`.
      '';
    };

    templates = mkOption {
      type = with types; attrsOf lines;
      default = { };
      example = literalExpression ''
        { new_message = "Hello!"; };
      '';
      description = ''
        Templates added to {file}`$HOME/.config/aerc/templates/`.

        See {manpage}`aerc-templates(7)`.
      '';
    };
  };

  config =
    let
      joinCfg = cfgs: lib.concatStringsSep "\n" (lib.filter (v: v != "") cfgs);

      sectionsToINI =
        conf:
        let
          global = conf.global or { };
          local = removeAttrs conf [ "global" ];
        in
        joinCfg ([ (sectionToINI "global" global) ] ++ (lib.mapAttrsToList sectionToINI local));

      sectionToINI =
        name: section:
        let
          # quirk: global section is prepended w/o section heading
          header = if name == "global" then "" else "[${lib.escape [ "[" "]" ] name}]\n";
          content =
            if lib.isString section then section else generators.toKeyValue { inherit mkKeyValue; } section;
        in
        if builtins.stringLength content > 0 then header + content else "";

      mkValueString =
        v:
        if lib.isList v then # join with comma
          lib.concatStringsSep "," (map (generators.mkValueStringDefault { }) v)
        else
          generators.mkValueStringDefault { } v;

      mkINI = conf: if lib.isString conf then conf else sectionsToINI conf;

      mkKeyValue = generators.mkKeyValueDefault { inherit mkValueString; } " = ";

      mkStyleset = attrsets.mapAttrs' (
        k: v:
        let
          value = if lib.isString v then v else sectionsToINI { global = v; };
        in
        {
          name = "${configDir}/stylesets/${k}";
          value.text = joinCfg [
            header
            value
          ];
        }
      );

      mkTemplates = attrsets.mapAttrs' (
        k: v: {
          name = "${configDir}/templates/${k}";
          value.text = v;
        }
      );

      primaryAccount = attrsets.filterAttrs (_: v: v.primary) aerc-accounts;
      otherAccounts = attrsets.filterAttrs (_: v: !v.primary) aerc-accounts;

      primaryAccountAccounts = mapAttrs accounts.mkAccount primaryAccount;

      accountsExtraAccounts = mapAttrs accounts.mkAccount otherAccounts;

      accountsExtraConfig = mapAttrs accounts.mkAccountConfig aerc-accounts;

      accountsExtraBinds = mapAttrs accounts.mkAccountBinds aerc-accounts;

      joinContextual = contextual: joinCfg (map mkINI (lib.attrValues contextual));

      isRecursivelyEmpty =
        x:
        if lib.isAttrs x then lib.all (x: x == { } || isRecursivelyEmpty x) (lib.attrValues x) else false;

      genAccountsConf = (
        (cfg.extraAccounts != "" && cfg.extraAccounts != { })
        || !(isRecursivelyEmpty accountsExtraAccounts)
        || !(isRecursivelyEmpty primaryAccountAccounts)
      );

      genAercConf = (
        (cfg.extraConfig != "" && cfg.extraConfig != { }) || !(isRecursivelyEmpty accountsExtraConfig)
      );

      genBindsConf = (
        (cfg.extraBinds != "" && cfg.extraBinds != { }) || !(isRecursivelyEmpty accountsExtraBinds)
      );

      header = ''
        # Generated by Home Manager.
      '';

    in
    mkIf cfg.enable {
      warnings =
        if genAccountsConf && (cfg.extraConfig.general.unsafe-accounts-conf or false) == false then
          [
            ''
              aerc: `programs.aerc.enable` is set, but `...extraConfig.general.unsafe-accounts-conf` is set to false or unset.
              This will prevent aerc from starting; see `unsafe-accounts-conf` in the man page aerc-config(5):
              > By default, the file permissions of accounts.conf must be restrictive and only allow reading by the file owner (0600).
              > Set this option to true to ignore this permission check. Use this with care as it may expose your credentials.
              These permissions are not possible with home-manager, since the generated file is in the nix-store (permissions 0444).
              Therefore, please set `programs.aerc.extraConfig.general.unsafe-accounts-conf = true`.
              This option is safe; if `passwordCommand` is properly set, no credentials will be written to the nix store.
            ''
          ]
        else
          [ ];

      assertions = [
        {
          assertion =
            let
              extraConfigSections = (
                lib.unique (lib.flatten (lib.mapAttrsToList (_: v: lib.attrNames v.aerc.extraConfig) aerc-accounts))
              );
            in
            extraConfigSections == [ ] || extraConfigSections == [ "ui" ];
          message = ''
            Only the ui section of $XDG_CONFIG_HOME/aerc.conf supports contextual (per-account) configuration.
            Please configure it with accounts.email.accounts._.aerc.extraConfig.ui and move any other
            configuration to programs.aerc.extraConfig.
          '';
        }
      ];

      home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      home.file = {
        "${configDir}/accounts.conf" = mkIf genAccountsConf {
          text = joinCfg [
            header
            (mkINI cfg.extraAccounts)
            (mkINI primaryAccountAccounts)
            (mkINI accountsExtraAccounts)
          ];
        };

        "${configDir}/aerc.conf" = mkIf genAercConf {
          text = joinCfg [
            header
            (mkINI cfg.extraConfig)
            (joinContextual accountsExtraConfig)
          ];
        };

        "${configDir}/binds.conf" = mkIf genBindsConf {
          text = joinCfg [
            header
            (mkINI cfg.extraBinds)
            (joinContextual accountsExtraBinds)
          ];
        };
      }
      // (mkStyleset cfg.stylesets)
      // (mkTemplates cfg.templates);
    };
}
