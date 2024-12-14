{ pkgs, config, lib, ... }:

let
  inherit (lib) mkEnableOption mkOption mkPackageOption optionalString;

  cfg = config.programs.git-worktree-switcher;

  initScript = shell:
    if (shell == "fish") then ''
      ${lib.getExe pkgs.git-worktree-switcher} init ${shell} | source
    '' else ''
      eval "$(${lib.getExe pkgs.git-worktree-switcher} init ${shell})"
    '';
in {
  meta.maintainers = with lib.maintainers; [ jiriks74 mateusauler ];

  options.programs.git-worktree-switcher = {
    enable = mkEnableOption "git-worktree-switcher";
    package = mkPackageOption pkgs "git-worktree-switcher" { };
    enableBashIntegration = mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to enable git-worktree-switcher's Bash integration.
      '';
    };
    enableFishIntegration = mkOption {
      type = lib.types.bool;
      default = config.programs.fish.enable;
      description = ''
        Whether to enable git-worktree-switcher's Fish integration.
      '';
    };
    enableZshIntegration = mkOption {
      type = lib.types.bool;
      default = config.programs.zsh.enable;
      description = ''
        Whether to enable git-worktree-switcher's Zsh integration.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    programs.bash.initExtra =
      optionalString cfg.enableBashIntegration (initScript "bash");
    programs.fish.interactiveShellInit =
      optionalString cfg.enableFishIntegration (initScript "fish");
    programs.zsh.initExtra =
      optionalString cfg.enableZshIntegration (initScript "zsh");
  };
}
