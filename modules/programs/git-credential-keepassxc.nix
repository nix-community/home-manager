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
      enable = lib.mkEnableOption "prompting KeePassXC to unlock a locked database";
      retries = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 0;
        example = 3;
        description = ''
          Number of times to check whether the database has been unlocked.
          `0` keeps waiting until it is unlocked.
        '';
      };
      interval = lib.mkOption {
        type = with lib.types; nullOr ints.unsigned;
        default = null;
        example = 1000;
        description = ''
          Delay between unlock checks in milliseconds. If `null`,
          {command}`git-credential-keepassxc` uses its default of 1000.
        '';
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
              ++ lib.optional cfg.unlock.enable (
                "--unlock ${toString cfg.unlock.retries}"
                + lib.optionalString (cfg.unlock.interval != null) ",${toString cfg.unlock.interval}"
              )
            );
          };
      in
      if cfg.hosts == [ ] then
        helperConfig
      else
        lib.listToAttrs (map (host: lib.nameValuePair host helperConfig) cfg.hosts);
  };

}
