{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.programs.worktrunk;
  wt = lib.getExe cfg.package;
  jq = lib.getExe pkgs.jq;
  tomlFormat = pkgs.formats.toml { };

  # Best-effort `wt config state marker` hook entry. `|| true` ensures a failure
  # (e.g. running outside a git worktree) never blocks Claude Code.
  mkMarkerHook = op: {
    type = "command";
    command = "${wt} config state marker ${op} || true";
  };
in
{
  meta.maintainers = [ lib.maintainers.yzx9 ];

  options.programs.worktrunk = {
    enable = lib.mkEnableOption "worktrunk - Git worktree management CLI";

    # Shipped by nixpkgs (binary `wt`). Override only to track a newer release.
    package = lib.mkPackageOption pkgs [ "worktrunk" ] { };

    # worktrunk user config → ~/.config/worktrunk/config.toml.
    # https://worktrunk.dev/config/  (e.g. LLM commits: settings.commit.generation)
    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          worktree-path = ".worktrees/{{ branch | sanitize }}";
          commit.stage = "all";
          commit.generation.command = "llm -m claude-haiku-4.5";
        }
      '';
      description = ''
        worktrunk user configuration, written to
        `$XDG_CONFIG_HOME/worktrunk/config.toml` (`~/.config/worktrunk/config.toml`).
        See <https://worktrunk.dev/config/> for the schema — e.g. LLM-generated
        commit messages live under `commit.generation`
        (<https://worktrunk.dev/llm-commits/>).
      '';
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };
    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };
    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    # Claude Code integration
    claudeCodeIntegration = {
      enable =
        lib.mkEnableOption "Integrate worktrunk with Claude Code's statusLine, worktree isolation, and skills"
        // {
          default = config.programs.claude-code.enable;
          defaultText = lib.literalExpression "config.programs.claude-code.enable";
        };

      # Route Claude Code worktree isolation (`isolation: "worktree"`) through `wt`
      # instead of `git worktree add`, so agent-created worktrees get worktrunk's
      # naming, hooks, and lifecycle. https://worktrunk.dev/claude-code/#worktree-isolation
      worktreeHooks = lib.mkEnableOption "Claude Code WorktreeCreate/WorktreeRemove hooks" // {
        default = cfg.claudeCodeIntegration.enable;
        defaultText = lib.literalExpression "config.programs.worktrunk.claudeCodeIntegration.enable";
      };

      # Activity tracking: mirror upstream's state-marker hooks so `wt list` (and
      # the statusline) show 🤖 (working) / 💬 (waiting) per branch, cleared on
      # session end. https://worktrunk.dev/claude-code/#activity-tracking
      activityTrackingHooks =
        lib.mkEnableOption "Claude Code activity-tracking state markers (🤖/💬 in wt list)"
        // {
          default = cfg.claudeCodeIntegration.enable;
          defaultText = lib.literalExpression "config.programs.worktrunk.claudeCodeIntegration.enable";
        };

      # Install the `/worktrunk` configuration skill (loads when editing worktrunk's
      # config/hooks). Off by default: `settings` already manages
      # `~/.config/worktrunk/config.toml`, and this skill would have the agent edit
      # it directly, clobbering the Home Manager-managed copy.
      configurationSkill = lib.mkEnableOption "worktrunk's /worktrunk configuration skill";

      # Install the `/wt-switch-create` skill — a slash command that creates a new
      # worktree and switches the session into it.
      switchCreateSkill = lib.mkEnableOption "worktrunk's /wt-switch-create skill" // {
        default = cfg.claudeCodeIntegration.enable;
        defaultText = lib.literalExpression "config.programs.worktrunk.claudeCodeIntegration.enable";
      };

      # Opt-in to use `wt` for Claude Code's statusLine, which shows the current worktree and branch.
      statusLine = lib.mkEnableOption "Claude Code statusLine powered by worktrunk" // {
        default = cfg.claudeCodeIntegration.enable;
        defaultText = lib.literalExpression "config.programs.worktrunk.claudeCodeIntegration.enable";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Write the user config (~/.config/worktrunk/config.toml) when set.
    xdg.configFile = lib.mkIf (cfg.settings != { }) {
      "worktrunk/config.toml".source = tomlFormat.generate "worktrunk-config.toml" cfg.settings;
    };

    programs.bash.initExtra = lib.mkIf cfg.enableBashIntegration ''
      eval "$(${wt} config shell init bash)"
    '';

    programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration ''
      eval "$(${wt} config shell init zsh)"
    '';

    programs.fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration ''
      ${wt} config shell init fish | source
    '';

    programs.nushell = lib.mkIf cfg.enableNushellIntegration {
      extraConfig = ''
        source ${
          pkgs.runCommand "worktrunk-nushell-config.nu" { } ''
            ${wt} config shell init nu > $out
          ''
        }
      '';
    };

    # Claude code integration: https://worktrunk.dev/claude-code/
    programs.claude-code = {
      settings = {
        hooks = lib.mkMerge [
          # Route Claude Code worktree create/remove through `wt` (worktree isolation).
          # Mirrors the upstream plugin's hooks, calling `wt`/`jq` by absolute nix path
          # so nothing depends on $PATH or the plugin being installed.
          (lib.mkIf cfg.claudeCodeIntegration.worktreeHooks {
            # stdin: {"name": "<branch>"} → creates a sibling worktree, prints its path.
            WorktreeCreate = [
              {
                hooks = [
                  {
                    type = "command";
                    command = "bash -c 'set -o pipefail; name=$(${jq} -er .name) || exit 1; cd \"\${CLAUDE_PROJECT_DIR:-.}\" || exit 1; ${wt} switch --create \"$name\" --no-cd --format=json | ${jq} -er .path'";
                  }
                ];
              }
            ];
            # stdin: {"worktree_path": "<path>"} → removes the worktree.
            WorktreeRemove = [
              {
                hooks = [
                  {
                    type = "command";
                    command = "bash -c 'p=$(${jq} -er .worktree_path) || exit 1; cd \"\${CLAUDE_PROJECT_DIR:-.}\" || exit 1; [ -e \"$p\" ] || exit 0; ${wt} remove --foreground \"$p\"'";
                  }
                ];
              }
            ];
          })

          # Activity tracking — mirrors the upstream plugin's marker hooks
          # (https://github.com/max-sixty/worktrunk/blob/main/plugins/worktrunk/hooks/hooks.json),
          # calling `wt` by absolute nix path. The hook-list type merges with
          # claude-code.nix's own hooks (e.g. the GUI Notification) by concatenation.
          (lib.mkIf cfg.claudeCodeIntegration.activityTrackingHooks {
            # 🤖 the user submitted a prompt → the agent is working.
            UserPromptSubmit = [
              {
                hooks = [ (mkMarkerHook "set 🤖") ];
              }
            ];
            # 💬 the agent paused and is waiting for the user.
            Notification = [
              {
                matcher = "";
                hooks = [ (mkMarkerHook "set 💬") ];
              }
            ];
            PreToolUse = [
              {
                matcher = "AskUserQuestion";
                hooks = [ (mkMarkerHook "set 💬") ];
              }
            ];
            PermissionRequest = [
              {
                matcher = "";
                hooks = [ (mkMarkerHook "set 💬") ];
              }
            ];
            Stop = [
              {
                hooks = [ (mkMarkerHook "set 💬") ];
              }
            ];
            # Clear the marker when the session ends.
            SessionEnd = [
              {
                matcher = "";
                hooks = [ (mkMarkerHook "clear") ];
              }
            ];
          })
        ];

        statusLine = lib.mkIf cfg.claudeCodeIntegration.statusLine {
          type = "command";
          command = "${wt} list statusline --format=claude-code";
        };
      };

      # Install worktrunk's skills directly into Claude Code (no plugin marketplace).
      # The skill markdown ships inside the nixpkgs `worktrunk` package,
      # version-aligned with the `wt` binary. Each skill has its own enable flag.
      skills = lib.mkMerge [
        (lib.mkIf cfg.claudeCodeIntegration.configurationSkill {
          worktrunk = "${cfg.package}/skills/worktrunk";
        })

        (lib.mkIf cfg.claudeCodeIntegration.switchCreateSkill {
          wt-switch-create = "${cfg.package}/skills/wt-switch-create";
        })
      ];
    };
  };
}
