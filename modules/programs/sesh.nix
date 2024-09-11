{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.programs.sesh;
  tomlFormat = pkgs.formats.toml { };
in {
  meta.maintainers = [ maintainers.michaelvanstraten ];

  options.programs.sesh = {
    enable = mkEnableOption "sesh";
    package = mkPackageOption pkgs "sesh" { };
    settings = mkOption {
      type = types.submodule { freeformType = tomlFormat.type; };
      default = { };
      description = ''
        Configuration settings for sesh, written to `~/.config/sesh/sesh.toml`.

        For more details, refer to the [sesh configuration documentation](https://github.com/joshmedeski/sesh?tab=readme-ov-file#configuration).
      '';
    };
    enableAlias = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable the `s` shell alias for sesh.
      '';
    };
    enableTmuxIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Tmux integration for sesh.
      '';
    };
    tmuxKey = mkOption {
      type = types.str;
      default = "s";
      description = ''
        The key to bind for the sesh command in tmux.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Sesh needs fzf installed by default
      home.packages = [ cfg.package pkgs.fzf ];
      home.shellAliases =
        mkIf cfg.enableAlias { s = "sesh connect $(sesh list | fzf)"; };
      home.file.".config/sesh/sesh.toml".source =
        tomlFormat.generate "sesh.toml" cfg.settings;
    }
    (mkIf cfg.enableTmuxIntegration {
      home.packages = [ pkgs.zoxide ];
      programs.fzf.tmux.enableShellIntegration = true;
      programs.tmux.extraConfig = ''
        bind-key "${cfg.tmuxKey}" run-shell "sesh connect \"$(
          sesh list | fzf-tmux -p 55%,60% \
            --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
            --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
            --bind 'tab:down,btab:up' \
            --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list)' \
            --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t)' \
            --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c)' \
            --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z)' \
            --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
            --bind 'ctrl-d:execute(tmux kill-session -t {})+change-prompt(⚡  )+reload(sesh list)'
        )\""
      '';
    })
  ]);
}
