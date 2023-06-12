{ config, lib, pkgs, ... }:

let

  cfg = config.programs.git-credential-oauth;

in {
  meta.maintainers = [ lib.maintainers.tomodachi94 ];

  options = {
    programs.git-credential-oauth = {
      enable = lib.mkEnableOption "Git authentication handler for OAuth";

      package = lib.mkPackageOption pkgs "git-credential-oauth" { };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.git.extraConfig.credential.helper =
      [ "${cfg.package}/bin/git-credential-oauth" ];
  };
}
