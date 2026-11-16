{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.worktrunk;
  tomlFormat = pkgs.formats.toml { };
  wt = lib.getExe cfg.package;

  mkClaudeCodeIntegrationEnableOption =
    msg:
    lib.mkEnableOption msg
    // {
      default = cfg.claudeCodeIntegration.enable;
      defaultText = lib.literalExpression "config.programs.worktrunk.claudeCodeIntegration.enable";
    };

  # Every hook runs the command upstream's plugin registers for each event
  # (https://github.com/max-sixty/worktrunk/blob/main/plugins/worktrunk/hooks/hooks.json).
  # It reads the event from the hook payload on stdin and handles it as the
  # plugin does, so the hooks' behavior follows the installed `wt`.
  claudeHook = {
    type = "command";
    command = "${wt} config plugins claude hook";
  };

  # Activity markers are best-effort, as in upstream's plugin: `|| true` keeps a
  # failure (e.g. running outside a git worktree) from blocking Claude Code.
  claudeMarkerHook = claudeHook // {
    command = "${claudeHook.command} || true";
  };

  skillsPackage = pkgs.runCommandLocal "worktrunk-skills" { } ''
    if [ -d "${cfg.package}/share/skills/worktrunk" ]; then
      ln -s "${cfg.package}/share/skills/worktrunk" "$out"
    else
      ln -s "${cfg.package}/skills" "$out"
    fi
  '';
in
{
  meta.maintainers = with lib.maintainers; [
    eveeifyeve
    yzx9
  ];

  options.programs.worktrunk = {
    enable = lib.mkEnableOption "worktrunk";

    package = lib.mkPackageOption pkgs "worktrunk" { nullable = true; };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        skip-shell-integration-prompt = true;
        post-start = {
          copy = "wt step copy-ignored";
        };
      };
      description = ''
        Configuration written to `$XDG_CONFIG_HOME/worktrunk/config.toml`.
      '';
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };
    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };
    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    # Claude Code integration.
    claudeCodeIntegration = {
      enable = lib.mkEnableOption "Integrate worktrunk with Claude Code's statusLine, worktree isolation, and skills";

      # Route Claude Code worktree isolation (`isolation: "worktree"`) through `wt`
      # instead of `git worktree add`, so agent-created worktrees get worktrunk's
      # naming, hooks, and lifecycle. https://worktrunk.dev/claude-code/#worktree-isolation
      worktreeHooks = mkClaudeCodeIntegrationEnableOption "Claude Code WorktreeCreate/WorktreeRemove hooks";

      # Activity tracking: mirror upstream's state-marker hooks so `wt list` (and
      # the statusline) show 🤖 (working) / 💬 (waiting) per branch, cleared on
      # session end. https://worktrunk.dev/claude-code/#activity-tracking
      activityTrackingHooks = mkClaudeCodeIntegrationEnableOption "Claude Code activity-tracking state markers (🤖/💬 in wt list)";

      # Install the `/worktrunk` configuration skill (loads when editing worktrunk's
      # config/hooks). Off by default: `settings` already manages
      # `~/.config/worktrunk/config.toml`, and this skill would have the agent edit
      # it directly, which is unsafe and may fail due to insufficient permissions.
      configurationSkill = lib.mkEnableOption ''
        Worktrunk's /worktrunk configuration skill.

        Warning: this should not be enabled together with `settings`, as the skill
        may attempt to modify the Home Manager-managed Worktrunk configuration file.
        Such edits will fail due to insufficient permissions and may cause the agent
        to attempt unsafe workarounds such as using elevated privileges
      '';

      # Install the `/wt-switch-create` skill — a slash command that creates a new
      # worktree and switches the session into it.
      switchCreateSkill = mkClaudeCodeIntegrationEnableOption "worktrunk's /wt-switch-create skill";

      # Opt-in to use `wt` for Claude Code's statusLine, which shows the current worktree and branch.
      statusLine = mkClaudeCodeIntegrationEnableOption "Claude Code statusLine powered by worktrunk";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optional (cfg.package != null) cfg.package;

    xdg.configFile."worktrunk/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "config.toml" cfg.settings;
    };

    # The shell integrations and the Claude Code integration below need the `wt`
    # binary, so they are inert when `package` is set to null.
    programs.bash.initExtra = lib.mkIf (cfg.enableBashIntegration && cfg.package != null) ''
      eval "$(${wt} config shell init bash)"
    '';

    programs.zsh.initContent = lib.mkIf (cfg.enableZshIntegration && cfg.package != null) ''
      eval "$(${wt} config shell init zsh)"
    '';

    programs.fish.interactiveShellInit = lib.mkIf (cfg.enableFishIntegration && cfg.package != null) ''
      ${wt} config shell init fish | source
    '';

    programs.nushell = lib.mkIf (cfg.enableNushellIntegration && cfg.package != null) {
      extraConfig = ''
        source ${
          pkgs.runCommand "worktrunk-nushell-config.nu" { } ''
            ${wt} config shell init nu > $out
          ''
        }
      '';
    };

    # Claude Code integration: https://worktrunk.dev/claude-code/
    programs.claude-code = lib.mkIf (cfg.package != null && cfg.claudeCodeIntegration.enable) {
      settings = {
        hooks = lib.mkMerge [
          # Route Claude Code worktree create/remove through `wt` (worktree isolation).
          # `wt` is called by absolute nix path, so nothing depends on $PATH or the
          # plugin being installed.
          (lib.mkIf cfg.claudeCodeIntegration.worktreeHooks {
            # Creates the worktree, or switches to the branch's existing one, and
            # prints its path.
            WorktreeCreate = [ { hooks = [ claudeHook ]; } ];
            WorktreeRemove = [ { hooks = [ claudeHook ]; } ];
          })

          # Activity tracking: 🤖 while the agent works, 💬 while it waits for the
          # user, cleared when the session ends. The hook-list type merges with
          # claude-code.nix's own hooks (e.g. the GUI Notification) by concatenation.
          (lib.mkIf cfg.claudeCodeIntegration.activityTrackingHooks {
            UserPromptSubmit = [ { hooks = [ claudeMarkerHook ]; } ];
            Notification = [
              {
                matcher = "";
                hooks = [ claudeMarkerHook ];
              }
            ];
            PreToolUse = [
              {
                matcher = "AskUserQuestion";
                hooks = [ claudeMarkerHook ];
              }
            ];
            # Also approves an EnterWorktree into a worktrunk-managed worktree.
            PermissionRequest = [
              {
                matcher = "";
                hooks = [ claudeMarkerHook ];
              }
            ];
            Stop = [ { hooks = [ claudeMarkerHook ]; } ];
            SessionEnd = [
              {
                matcher = "";
                hooks = [ claudeMarkerHook ];
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
      # The skills ship inside the nixpkgs `worktrunk` package, version-aligned with
      # the `wt` binary. Each skill has its own enable flag.
      skills = lib.mkMerge [
        (lib.mkIf cfg.claudeCodeIntegration.configurationSkill {
          worktrunk = "${skillsPackage}/worktrunk";
        })

        (lib.mkIf cfg.claudeCodeIntegration.switchCreateSkill {
          wt-switch-create = "${skillsPackage}/wt-switch-create";
        })
      ];
    };
  };
}
