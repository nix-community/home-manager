{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkOption types;
  cfg = config.programs.claude-code;
in {
  meta.maintainers = with lib.maintainers; [ malo ];

  options.programs.claude-code = {
    enable = lib.mkEnableOption "Claude Code CLI";

    package = lib.mkPackageOption pkgs "claude-code" { };

    disableAutoUpdate = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to disable the automatic update check on startup.
        This is recommended when using home-manager to manage {command}`claude`.
      '';
    };

    enableOptionalDependencies = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to install the optional dependencies for {command}`claude`.
        This includes:
        - {command}`git` (for git operations)
        - {command}`rg` (for code search)
        - {command}`gh` (GitHub CLI, for GitHub operations)
        - {command}`glab` (GitLab CLI, for GitLab operations)
      '';
    };

    withGitHubCLI = mkOption {
      type = types.bool;
      default = cfg.enableOptionalDependencies;
      description = ''
        Whether to enable GitHub CLI ({command}`gh`) as a dependency.
        This is useful if you work with GitHub repositories.

        Defaults to the value of {option}`programs.claude-code.enableOptionalDependencies`.
      '';
    };

    withGitLabCLI = mkOption {
      type = types.bool;
      default = cfg.enableOptionalDependencies;
      description = ''
        Whether to install GitLab CLI ({command}`glab`) as a dependency.
        This is useful if you work with GitLab repositories.

        Defaults to the value of {option}`programs.claude-code.enableOptionalDependencies`.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ] ++ lib.optional cfg.withGitLabCLI pkgs.glab;

    # Enable integrated modules for dependencies when needed
    programs.git.enable = mkIf cfg.enableOptionalDependencies true;
    programs.gh.enable = mkIf cfg.withGitHubCLI true;
    programs.ripgrep.enable = mkIf cfg.enableOptionalDependencies true;

    # Add activation script to disable auto-updates if the user wants that
    home.activation.disableClaudeAutoUpdates = lib.mkIf cfg.disableAutoUpdate
      (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${
          lib.getExe cfg.package
        } config set -g autoUpdaterStatus disabled || true
      '');
  };
}
