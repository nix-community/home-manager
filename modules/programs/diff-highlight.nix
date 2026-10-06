{
  config,
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

  imports =
    lib.mapAttrsToList
      (name: message: lib.mkRemovedOptionModule [ "programs" "git" "diff-highlight" name ] message)
      {
        enable = "Use `programs.diff-highlight.enable` and `programs.diff-highlight.enableGitIntegration` instead.";
        pagerOpts = "Use `programs.diff-highlight.pagerOpts` instead.";
      };

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

        When enabled, diff-highlight will be configured as git's pager for
        {command}`diff`, {command}`log`, and {command}`show`, and as git's diff
        filter for interactive staging.
      '';
    };
  };

  config = lib.mkMerge [
    (mkIf cfg.enable {
      assertions = [
        {
          assertion = !cfg.enableGitIntegration || config.programs.git.package != null;
          message = ''
            programs.diff-highlight.enableGitIntegration requires programs.git.package to be set.
            Please set programs.git.package to a valid git package.
          '';
        }
      ];
    })

    (mkIf (cfg.enable && cfg.enableGitIntegration && config.programs.git.package != null) {
      programs.git = {
        enable = lib.mkDefault true;
        iniContent =
          let
            gitPackage = config.programs.git.package;
            dhCommand = "${gitPackage}/share/git/contrib/diff-highlight/diff-highlight";
            pagerCommand = "${dhCommand} | ${lib.getExe pkgs.less} ${lib.escapeShellArgs cfg.pagerOpts}";
          in
          lib.hm.git.diffPagerConfig pagerCommand
          // {
            interactive.diffFilter = dhCommand;
          };
      };
    })
  ];
}
