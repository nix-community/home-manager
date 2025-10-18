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

  imports =
    let
      oldPrefix = [
        "programs"
        "diff-so-fancy"
      ];
      newPrefix = [
        "programs"
        "diff-so-fancy"
        "settings"
      ];
      renamedOptions = [
        "markEmptyLines"
        "changeHunkIndicators"
        "stripLeadingSymbols"
        "useUnicodeRuler"
        "rulerWidth"
      ];
    in
    [
      (lib.mkRenamedOptionModule
        [ "programs" "git" "diff-so-fancy" "enable" ]
        [ "programs" "diff-so-fancy" "enable" ]
      )
      (lib.mkRenamedOptionModule
        [ "programs" "git" "diff-so-fancy" "pagerOpts" ]
        [ "programs" "diff-so-fancy" "pagerOpts" ]
      )
    ]
    ++ (lib.hm.deprecations.mkSettingsRenamedOptionModules oldPrefix newPrefix {
      transform = x: x;
    } renamedOptions)
    ++ (lib.hm.deprecations.mkSettingsRenamedOptionModules [
      "programs"
      "git"
      "diff-so-fancy"
    ] newPrefix { transform = x: x; } renamedOptions);

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

    settings = mkOption {
      type =
        with types;
        let
          primitiveType = oneOf [
            str
            bool
            int
          ];
        in
        attrsOf primitiveType;
      default = { };
      example = {
        markEmptyLines = true;
        changeHunkIndicators = true;
        stripLeadingSymbols = true;
        useUnicodeRuler = true;
        rulerWidth = 80;
      };
      description = ''
        Options to configure diff-so-fancy. See
        <https://github.com/so-fancy/diff-so-fancy#configuration> for available options.
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
              diff-so-fancy = cfg.settings;
            };
        };
      })
    ];
}
