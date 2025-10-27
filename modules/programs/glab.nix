{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.glab;

  yaml = pkgs.formats.yaml { };

in
{
  meta.maintainers = [ lib.maintainers.bmrips ];

  options.programs.glab = {
    enable = lib.mkEnableOption "{command}`glab`.";
    package = lib.mkPackageOption pkgs "glab" { nullable = true; };
    aliases = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = { };
      description = "Aliases written to {file}`$XDG_CONFIG_HOME/glab-cli/aliases.yml`.";
      example.co = "mr checkout";
    };
    settings = lib.mkOption {
      inherit (yaml) type;
      default = { };
      description = "Configuration written to {file}`$XDG_CONFIG_HOME/glab-cli/config.yml`.";
      example.check_update = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    # Use `systemd-tmpfiles` since glab requires its configuration file to have
    # mode 0600.
    systemd.user.tmpfiles.rules =
      let
        target = "${config.xdg.configHome}/glab-cli/config.yml";
      in
      lib.mkIf (cfg.settings != { }) [
        "C+ ${target} - - - - ${yaml.generate "glab-config" cfg.settings}"
        "z  ${target} 0600"
      ];

    xdg.configFile."glab-cli/aliases.yml" = lib.mkIf (cfg.aliases != { }) {
      source = yaml.generate "glab-aliases" cfg.aliases;
    };
  };
}
