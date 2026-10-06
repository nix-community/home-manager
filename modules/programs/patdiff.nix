{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.patdiff;

  inherit (lib)
    mkEnableOption
    mkIf
    mkPackageOption
    mkOption
    types
    ;
in
{
  meta.maintainers = with lib.maintainers; [ khaneliman ];

  imports =
    lib.mapAttrsToList
      (name: message: lib.mkRemovedOptionModule [ "programs" "git" "patdiff" name ] message)
      {
        enable = "Use `programs.patdiff.enable` and `programs.patdiff.enableGitIntegration` instead.";
        package = "Use `programs.patdiff.package` instead.";
      };

  options.programs.patdiff = {
    enable = mkEnableOption "" // {
      description = ''
        Whether to enable the {command}`patdiff` differ.
        See <https://opensource.janestreet.com/patdiff/>
      '';
    };

    package = mkPackageOption pkgs "patdiff" { };

    enableGitIntegration = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable git integration for patdiff.

        When enabled, patdiff will be configured as git's external diff tool.
      '';
    };
  };

  config = lib.mkMerge [
    (mkIf cfg.enable {
      home.packages = [ cfg.package ];
    })

    (mkIf (cfg.enable && cfg.enableGitIntegration) {
      programs.git = {
        enable = lib.mkDefault true;
        iniContent =
          let
            patdiffCommand = "${lib.getExe' cfg.package "patdiff-git-wrapper"}";
          in
          {
            diff.external = patdiffCommand;
          };
      };
    })
  ];
}
