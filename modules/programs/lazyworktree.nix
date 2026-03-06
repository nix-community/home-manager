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

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    shellWrapperName = mkOption {
      type = lib.types.str;
      default = "lwt";
      example = "wt";
      description = ''
        Name of the shell wrapper that launches lazyworktree and changes to the
        selected worktree directory on exit.
        This option only has an effect when at least one shell integration
        option is enabled.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."lazyworktree/config.yaml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "lazyworktree.yaml" cfg.settings;
    };

    programs = {
      bash.initExtra = mkIf cfg.enableBashIntegration ''
        function ${cfg.shellWrapperName}() {
          local lazyworktree_dir
          lazyworktree_dir="$(command lazyworktree "$@")" || return
          [ -n "$lazyworktree_dir" ] && [ -d "$lazyworktree_dir" ] && cd "$lazyworktree_dir"
        }
      '';

      zsh.initContent = mkIf cfg.enableZshIntegration ''
        function ${cfg.shellWrapperName}() {
          local lazyworktree_dir
          lazyworktree_dir="$(command lazyworktree "$@")" || return
          [ -n "$lazyworktree_dir" ] && [ -d "$lazyworktree_dir" ] && cd "$lazyworktree_dir"
        }
      '';

      fish.functions.${cfg.shellWrapperName} = mkIf cfg.enableFishIntegration ''
        set -l lazyworktree_dir (command lazyworktree $argv)
        or return

        if test -n "$lazyworktree_dir"; and test -d "$lazyworktree_dir"
          cd "$lazyworktree_dir"
        end
      '';
    };
  };
}
