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
        auto_fetch_prs = false;
        auto_refresh = true;
        refresh_interval = 10;
        icon_set = "nerd-font-v3";
        search_auto_select = false;
        fuzzy_finder_input = false;
      };
      description = ''
        Configuration settings for lazyworktree. All the available options can be found here:
        <https://github.com/chmouel/lazyworktree?tab=readme-ov-file#global-configuration-yaml>
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
