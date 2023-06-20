{ config, lib, pkgs, ... }:
let cfg = config.programs.git-workspace;
in {
  meta.maintainers = [ lib.maintainers.aciceri ];
  options.programs.git-workspace = {
    enable = lib.mkEnableOption "git-workspace";
    package = mkPackageOption pkgs "git-workspace" { };
  };
  config = lib.mkIf cfg.enable { home.packages = [ pkgs.git-workspace ]; };
}
