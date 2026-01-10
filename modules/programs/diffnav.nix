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

    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      visible = false;
      default =
        let
          configFile = pkgs.writeText "diffnav-config" (lib.generators.toYAML { diffnav = cfg.options; });
          wrappedDiffnav = pkgs.symlinkJoin {
            name = "diffnav-wrapped";
            paths = [ cfg.package ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/diffnav \
                --set "DIFFNAV_CONFIG_DIR" "$(pathname "${configFile}")"
            '';
            inherit (cfg.package) meta;
          };
        in
        if cfg.options != { } then wrappedDiffnav else cfg.package;
      description = ''
        The diffnav package with configuration wrapper applied.

        When options are configured, this is a wrapped version that passes the
        configuration to diffnav. Otherwise, it's the unwrapped package.
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
        home.packages = [ cfg.finalPackage ];

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
