{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.diffnav;

  inherit (lib)
    mkOption
    types
    ;
in
{
  meta.maintainers = with lib.maintainers; [ matthiasbeyer ];

  options.programs.diffnav = {
    enable = lib.mkEnableOption "diffnav, a git diff pager based on delta but with a file tree, à la GitHub";

    package = lib.mkPackageOption pkgs "diffnav" { };

    settings = mkOption {
      type = pkgs.formats.yaml;

      default = { };

      example = {
        ui = {
          hideHeader = true;
          hideFooter = true;
          showFileTree = false;
          fileTreeWidth = 30;
          searchTreeWidth = 60;
        };
      };

      description = ''
        Options to configure diffnav.
      '';
    };

    enableGitIntegration = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable git integration for diffnav.

        When enabled, diffnav will be configured as git's diff filter.
      '';
    };
  };

  config =
    let
      oldOption = lib.attrByPath [ "programs" "git" "diffnav" "enable" ] null options;
      oldOptionEnabled =
        oldOption != null && oldOption.isDefined && (builtins.length oldOption.files) > 0;
    in
    lib.mkMerge [
      (lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];

        programs.diffnav.enableGitIntegration = lib.mkIf oldOptionEnabled (lib.mkOverride 1490 true);
      })

      (lib.mkIf (cfg.enable && cfg.enableGitIntegration) {
        programs.git.iniContent =
          let
            diffnavCommand = lib.getExe cfg.package;
          in
          {
            interactive.diffFilter = diffnavCommand;
            pager.diff = diffnavCommand;
          };
      })
    ];
}
