{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.diff-so-fancy;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
in
{
  meta.maintainers = with lib.maintainers; [ khaneliman ];

  imports = [
    (lib.mkRenamedOptionModule
      [ "programs" "git" "diff-so-fancy" "enable" ]
      [ "programs" "diff-so-fancy" "enable" ]
    )
    (lib.mkRenamedOptionModule
      [ "programs" "git" "diff-so-fancy" "pagerOpts" ]
      [ "programs" "diff-so-fancy" "pagerOpts" ]
    )
    (lib.mkRenamedOptionModule
      [ "programs" "git" "diff-so-fancy" "markEmptyLines" ]
      [ "programs" "diff-so-fancy" "markEmptyLines" ]
    )
    (lib.mkRenamedOptionModule
      [ "programs" "git" "diff-so-fancy" "changeHunkIndicators" ]
      [ "programs" "diff-so-fancy" "changeHunkIndicators" ]
    )
    (lib.mkRenamedOptionModule
      [ "programs" "git" "diff-so-fancy" "stripLeadingSymbols" ]
      [ "programs" "diff-so-fancy" "stripLeadingSymbols" ]
    )
    (lib.mkRenamedOptionModule
      [ "programs" "git" "diff-so-fancy" "useUnicodeRuler" ]
      [ "programs" "diff-so-fancy" "useUnicodeRuler" ]
    )
    (lib.mkRenamedOptionModule
      [ "programs" "git" "diff-so-fancy" "rulerWidth" ]
      [ "programs" "diff-so-fancy" "rulerWidth" ]
    )
  ];

  options.programs.diff-so-fancy = {
    enable = mkEnableOption "diff-so-fancy, a diff colorizer";

    pagerOpts = mkOption {
      type = types.listOf types.str;
      default = [
        "--tabs=4"
        "-RFX"
      ];
      description = ''
        Arguments to be passed to {command}`less`.
      '';
    };

    markEmptyLines = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether the first block of an empty line should be colored.
      '';
    };

    changeHunkIndicators = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Simplify git header chunks to a more human readable format.
      '';
    };

    stripLeadingSymbols = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether the `+` or `-` at
        line-start should be removed.
      '';
    };

    useUnicodeRuler = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        By default, the separator for the file header uses Unicode
        line-drawing characters. If this is causing output errors on
        your terminal, set this to false to use ASCII characters instead.
      '';
    };

    rulerWidth = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = false;
      description = ''
        By default, the separator for the file header spans the full
        width of the terminal. Use this setting to set the width of
        the file header manually.
      '';
    };

    enableGitIntegration = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable git integration for diff-so-fancy.

        When enabled, diff-so-fancy will be configured as git's pager and diff filter.
      '';
    };
  };

  config =
    let
      oldOption = lib.attrByPath [ "programs" "git" "diff-so-fancy" "enable" ] null options;
      oldOptionEnabled =
        oldOption != null && oldOption.isDefined && (builtins.length oldOption.files) > 0;
    in
    lib.mkMerge [
      (mkIf cfg.enable {
        home.packages = [ pkgs.diff-so-fancy ];

        # Auto-enable git integration if programs.git.diff-so-fancy.enable was set to true
        programs.diff-so-fancy.enableGitIntegration = lib.mkIf oldOptionEnabled (lib.mkOverride 1490 true);

        warnings =
          lib.optional
            (
              cfg.enableGitIntegration && options.programs.diff-so-fancy.enableGitIntegration.highestPrio == 1490
            )
            "`programs.diff-so-fancy.enableGitIntegration` automatic enablement is deprecated. Please explicitly set `programs.diff-so-fancy.enableGitIntegration = true`.";
      })

      (mkIf (cfg.enable && cfg.enableGitIntegration) {
        programs.git = {
          enable = lib.mkDefault true;
          iniContent =
            let
              dsfCommand = "${pkgs.diff-so-fancy}/bin/diff-so-fancy";
            in
            {
              core.pager = "${dsfCommand} | ${pkgs.less}/bin/less ${lib.escapeShellArgs cfg.pagerOpts}";
              interactive.diffFilter = "${dsfCommand} --patch";
              diff-so-fancy = {
                markEmptyLines = cfg.markEmptyLines;
                changeHunkIndicators = cfg.changeHunkIndicators;
                stripLeadingSymbols = cfg.stripLeadingSymbols;
                useUnicodeRuler = cfg.useUnicodeRuler;
                rulerWidth = mkIf (cfg.rulerWidth != null) cfg.rulerWidth;
              };
            };
        };
      })
    ];
}
