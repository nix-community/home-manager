{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;
  cfg = config.programs.lazyworktree;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.lazyworktree = {
    enable = mkEnableOption "lazyworktree";

    package = mkPackageOption pkgs "lazyworktree" { nullable = true; };

    settings = mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = {
        worktree_dir = "~/.local/share/worktrees";
        sort_mode = "switched";
        layout = "default";
        auto_refresh = true;
        ci_auto_refresh = false;
        refresh_interval = 10;
        disable_pr = false;
        icon_set = "nerd-font-v3";
        search_auto_select = false;
        fuzzy_finder_input = false;
        palette_mru = true;
        palette_mru_limit = 5;
      };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/lazyworktree/config.yaml`.
        See
        <https://github.com/chmouel/lazyworktree?tab=readme-ov-file#global-configuration-yaml>
        for supported values.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."lazyworktree/config.yaml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "lazyworktree.yaml" cfg.settings;
    };
  };
}
