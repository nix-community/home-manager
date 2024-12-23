{ config, lib, pkgs, ... }:

{
  lib.meta.maintainers = with lib.maintainers; [ jiriks74 ];

  options.programs.git-worktree-switcher = {
    enable = lib.mkEnableOption
      "git-worktree-switcher - Switch between git worktrees with speed.";
  };

  config = let
    initScript = shell:
      if (shell == "fish") then ''
        ${lib.getExe pkgs.git-worktree-switcher} init ${shell} | source
      '' else ''
        eval "$(${lib.getExe pkgs.git-worktree-switcher} init ${shell})"
      '';
  in lib.mkIf config.programs.git-worktree-switcher.enable {
    home.packages = [ pkgs.git-worktree-switcher ];

    config.programs.bash.interactiveShellInit = initScript "bash";
    config.programs.zsh.interactiveShellInit =
      lib.optionalString config.programs.zsh.enable (initScript "zsh");
    config.programs.fish.interactiveShellInit =
      lib.optionalString config.programs.fish.enable (initScript "fish");
  };
}
