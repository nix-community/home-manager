{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.git-credential-keepassxc;
in
{

  meta.maintainers = [ lib.maintainers.bmrips ];

  options.programs.git-credential-keepassxc = {
    enable = lib.mkEnableOption "{command}`git-credential-keepassxc`.";
    package = lib.mkPackageOption pkgs "git-credential-keepassxc" { };
    groups = lib.mkOption {
      type = with lib.types; nullOr (listOf str);
      default = null;
      example = "Git";
      description = ''
        The KeePassXC groups used for storing and fetching of credentials. By
        default, the groups created by
        {command}`git-credential-keepassxc configure [--group <GROUP>]` are used.
      '';
    };
    hosts = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      example = [ "https://github.com" ];
      description = "Hosts for which {command}`git-credential-keepassxc` is enabled.";
    };
    unlock = {
      enable = lib.mkOption {
        type = with lib.types; bool;
        default = false;
        example = true;
        description = "Try unlocking the database";
      };
      retries = lib.mkOption {
        type = with lib.types; int;
        default = 0;
        example = 3;
        description = "Number of unlocking attempts (0 means infinite retries)";
      };
      interval = lib.mkOption {
        type = with lib.types; int;
        default = 1000;
        example = 2000;
        description = "Number of ms between attempts";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    programs.git.settings.credential =
      let
        helperConfig =
          let
            groups =
              if cfg.groups == null then
                "--git-groups"
              else
                lib.concatStringsSep " " (map (g: "--group ${g}") cfg.groups);
          in
          {
            helper = lib.concatStringsSep " " (
              [
                "${cfg.package}/bin/git-credential-keepassxc"
                groups
              ]
              ++ lib.optional cfg.unlock.enable "--unlock ${toString cfg.unlock.retries},${toString cfg.unlock.interval}"
            );
          };
      in
      if cfg.hosts == [ ] then
        helperConfig
      else
        lib.listToAttrs (map (host: lib.nameValuePair host helperConfig) cfg.hosts);
  };

}
