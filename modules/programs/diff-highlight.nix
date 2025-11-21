{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.diff-highlight;

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
      [ "programs" "git" "diff-highlight" "enable" ]
      [ "programs" "diff-highlight" "enable" ]
    )
    (lib.mkRenamedOptionModule
      [ "programs" "git" "diff-highlight" "pagerOpts" ]
      [ "programs" "diff-highlight" "pagerOpts" ]
    )
  ];

  options.programs.diff-highlight = {
    enable = mkEnableOption "" // {
      description = ''
        Enable the contrib {command}`diff-highlight` syntax highlighter.
        See <https://github.com/git/git/blob/master/contrib/diff-highlight/README>,
      '';
    };

    pagerOpts = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "--tabs=4"
        "-RFX"
      ];
      description = ''
        Arguments to be passed to {command}`less`.
      '';
    };

    enableGitIntegration = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable git integration for diff-highlight.

        When enabled, diff-highlight will be configured as git's pager and diff filter.
      '';
    };
  };

  config =
    let
      oldOption = lib.attrByPath [ "programs" "git" "diff-highlight" "enable" ] null options;
      oldOptionEnabled =
        oldOption != null && oldOption.isDefined && (builtins.length oldOption.files) > 0;
    in
    lib.mkMerge [
      (mkIf cfg.enable {
        # Auto-enable git integration if programs.git.diff-highlight.enable was set to true
        programs.diff-highlight.enableGitIntegration = lib.mkIf oldOptionEnabled (lib.mkOverride 1490 true);

        warnings =
          lib.optional
            (
              cfg.enableGitIntegration && options.programs.diff-highlight.enableGitIntegration.highestPrio == 1490
            )
            "`programs.diff-highlight.enableGitIntegration` automatic enablement is deprecated. Please explicitly set `programs.diff-highlight.enableGitIntegration = true`.";
      })

      (mkIf (cfg.enable && cfg.enableGitIntegration) {
        programs.git = {
          enable = lib.mkDefault true;
          iniContent =
            let
              gitPackage = config.programs.git.package;
              dhCommand = "${gitPackage}/share/git/contrib/diff-highlight/diff-highlight";
            in
            {
              core.pager = "${dhCommand} | ${lib.getExe pkgs.less} ${lib.escapeShellArgs cfg.pagerOpts}";
              interactive.diffFilter = dhCommand;
            };
        };
      })
    ];
}
