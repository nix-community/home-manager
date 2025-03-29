{ pkgs, lib, config, ... }:

let
  inherit (lib) mkEnableOption mkIf mkMerge mkOption mkPackageOption types;

  cfg = config.programs.sesh;
  tomlFormat = pkgs.formats.toml { };
in {
  meta.maintainers = [ lib.hm.maintainers.michaelvanstraten ];

  options.programs.sesh = {
    enable = mkEnableOption "the sesh terminal session manager";

    package = mkPackageOption pkgs "sesh" { };
    fzfPackage = mkPackageOption pkgs "fzf" { nullable = true; };
    zoxidePackage = mkPackageOption pkgs "zoxide" { nullable = true; };

    settings = mkOption {
      type = types.submodule { freeformType = tomlFormat.type; };
      default = { };
      description = ''
        Configuration for sesh, written to `~/.config/sesh/sesh.toml`.

        See the [sesh documentation](https://github.com/joshmedeski/sesh#configuration) for available options.
      '';
    };

    enableAlias = mkOption {
      type = types.bool;
      default = true;
      description =
        "Whether to enable a shell alias `s` to quickly launch sessions.";
    };

    enableTmuxIntegration = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Tmux integration with sesh.";
    };

    tmuxKey = mkOption {
      type = types.str;
      default = "s";
      description = "Keybinding for invoking sesh in Tmux.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ cfg.package ];
      home.file.".config/sesh/sesh.toml".source =
        tomlFormat.generate "sesh.toml" cfg.settings;
    }

    (mkIf cfg.enableAlias {
      home.packages = lib.mkIf (cfg.fzfPackage != null) [ cfg.fzfPackage ];
      home.shellAliases.s = "sesh connect $(sesh list | fzf)";
    })

    (mkIf cfg.enableTmuxIntegration {
      assertions = [{
        assertion = config.programs.fzf.tmux.enableShellIntegration;
        message =
          "To use Tmux integration with sesh, enable `programs.fzf.tmux.enableShellIntegration`.";
      }];

      home.packages =
        lib.mkIf (cfg.zoxidePackage != null) [ cfg.zoxidePackage ];

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
