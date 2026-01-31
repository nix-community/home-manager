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
    {
      home.packages = lib.mkIf cfg.enable [ cfg.package ];

      xdg.configFile."diffnav/config.yml".text = (
        lib.mkIf cfg.enable (
          pkgs.writeText "diffnav-config" (lib.generators.toYAML { diffnav = cfg.options; })
        )
      );

      programs.git.iniContent =
        let
          diffnavCommand = lib.getExe cfg.package;
        in
        (lib.mkIf (cfg.enable && cfg.enableGitIntegration) {
          interactive.diffFilter = diffnavCommand;
          pager.diff = diffnavCommand;
        });
    };
}
