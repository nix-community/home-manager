{ config, lib, pkgs, ... }:

let

  cfg = config.programs.git-credential-oauth;

in {
  meta.maintainers = [ lib.maintainers.tomodachi94 ];

  options = {
    programs.git-credential-oauth = {
      enable = lib.mkEnableOption "Git authentication handler for OAuth";

      package = lib.mkPackageOption pkgs "git-credential-oauth" { };

      extraFlags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = lib.literalExpression ''[ "-device" ]'';
        description = ''
          Extra command-line arguments passed to git-credential-oauth.

          For valid arguments, see {manpage}`git-credential-oauth(1)`.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.git.extraConfig.credential.helper = lib.mkAfter [
      ("${cfg.package}/bin/git-credential-oauth"
        + lib.optionalString (cfg.extraFlags != [ ])
        " ${lib.strings.concatStringsSep " " cfg.extraFlags}")
    ];
  };
}
