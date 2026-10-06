{
  config,
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
    (lib.mapAttrsToList
      (name: message: lib.mkRemovedOptionModule [ "programs" "git" "diff-so-fancy" name ] message)
      {
        enable = "Use `programs.diff-so-fancy.enable` and `programs.diff-so-fancy.enableGitIntegration` instead.";
        pagerOpts = "Use `programs.diff-so-fancy.pagerOpts` instead.";
        changeHunkIndicators = "Use `programs.diff-so-fancy.settings.changeHunkIndicators` instead.";
        markEmptyLines = "Use `programs.diff-so-fancy.settings.markEmptyLines` instead.";
        rulerWidth = "Use `programs.diff-so-fancy.settings.rulerWidth` instead.";
        stripLeadingSymbols = "Use `programs.diff-so-fancy.settings.stripLeadingSymbols` instead.";
        useUnicodeRuler = "Use `programs.diff-so-fancy.settings.useUnicodeRuler` instead.";
      }
    )
    ++ (lib.mapAttrsToList
      (name: message: lib.mkRemovedOptionModule [ "programs" "diff-so-fancy" name ] message)
      {
        changeHunkIndicators = "Use `programs.diff-so-fancy.settings.changeHunkIndicators` instead.";
        markEmptyLines = "Use `programs.diff-so-fancy.settings.markEmptyLines` instead.";
        rulerWidth = "Use `programs.diff-so-fancy.settings.rulerWidth` instead.";
        stripLeadingSymbols = "Use `programs.diff-so-fancy.settings.stripLeadingSymbols` instead.";
        useUnicodeRuler = "Use `programs.diff-so-fancy.settings.useUnicodeRuler` instead.";
      }
    );

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

        When enabled, diff-so-fancy will be configured as git's pager for
        {command}`diff`, {command}`log`, and {command}`show`, and as git's diff
        filter for interactive staging.
      '';
    };
  };

  config = lib.mkMerge [
    (mkIf cfg.enable {
      home.packages = [ pkgs.diff-so-fancy ];
    })

    (mkIf (cfg.enable && cfg.enableGitIntegration) {
      programs.git = {
        enable = lib.mkDefault true;
        iniContent =
          let
            dsfCommand = "${pkgs.diff-so-fancy}/bin/diff-so-fancy";
            pagerCommand = "${dsfCommand} | ${pkgs.less}/bin/less ${lib.escapeShellArgs cfg.pagerOpts}";
          in
          lib.hm.git.diffPagerConfig pagerCommand
          // {
            interactive.diffFilter = "${dsfCommand} --patch";
            diff-so-fancy = cfg.settings;
          };
      };
    })
  ];
}
