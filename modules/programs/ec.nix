{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.programs.ec;
  ec = lib.getExe cfg.package;
in
{
  meta.maintainers = [ lib.maintainers.kpbaks ];

  options = {
    programs.ec = {
      enable = lib.mkEnableOption "ec, 3-way terminal native Git merge conflict resolver";
      package = lib.mkPackageOption pkgs "ec" { };

      enableGitIntegration = lib.mkOption {
        type = lib.types.bool;
        description = ''
          Whether to enable git integration for ec.

          When enabled, ec will be configured as git's merge tool.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.git.settings = lib.mkIf cfg.enableGitIntegration {
      merge.tool = "ec";
      mergetool.ec = {
        cmd = ''${ec} "$BASE" "$LOCAL" "$REMOTE" "$MERGED"'';
        trustExitCode = true;
      };
    };
  };
}
