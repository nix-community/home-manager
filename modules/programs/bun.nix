{ config, lib, pkgs, ... }:

let
  cfg = config.programs.bun;
  tomlFormat = pkgs.formats.toml { };
in {
  meta.maintainers = [ lib.hm.maintainers.jack5079 ];

  options.programs.bun = {
    enable = lib.mkEnableOption "Bun JavaScript runtime";

    package = lib.mkPackageOption pkgs "bun" { };

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          smol = true;
          telemetry = false;
          test = {
            coverage = true;
            coverageThreshold = 0.9;
          };
          install.lockfile = {
            print = "yarn";
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/.bunfig.toml`.

        See <https://bun.sh/docs/runtime/bunfig>
        for the full list of options.
      '';
    };

    enableGitIntegration = lib.mkEnableOption "Git integration" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile.".bunfig.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "bun-config" cfg.settings;
    };

    # https://bun.sh/docs/install/lockfile#how-do-i-git-diff-bun-s-lockfile
    programs.git.attributes =
      lib.mkIf cfg.enableGitIntegration [ "*.lockb binary diff=lockb" ];
    programs.git.extraConfig.diff.lockb = lib.mkIf cfg.enableGitIntegration {
      textconv = lib.getExe cfg.package;
      binary = true;
    };
  };
}
