{ pkgs, config, lib, ... }:

let
  inherit (lib) mkEnableOption mkPackageOption optionalString;

  cfg = config.programs.git-worktree-switcher;
in {
  meta.maintainers = with lib.maintainers; [ jiriks74 mateusauler ];

  imports = lib.flip builtins.map [ "Bash" "Fish" "Zsh" ]
    (shell: lib.mkRemovedOptionModule [
      "programs"
      "git-worktree-switcher"
      "enable${shell}Integration"
    ] ''
      The completion files for `git-worktree-switcher` are already installed in
      the package, and should be installed alongside it.
    '');

  options.programs.git-worktree-switcher = {
    enable = mkEnableOption "git-worktree-switcher";
    package = mkPackageOption pkgs "git-worktree-switcher" { };
  };

  config = lib.mkIf cfg.enable { home.packages = [ cfg.package ]; };
}
