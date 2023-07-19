{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.watson;

  iniFormat = pkgs.formats.ini { };

  configDir = if pkgs.stdenv.hostPlatform.isDarwin then
    "Library/Application Support"
  else
    config.xdg.configHome;

in {
  meta.maintainers = [ maintainers.polykernel ];

  options.programs.watson = {
    enable = mkEnableOption "watson, a wonderful CLI to track your time";

    package = mkOption {
      type = types.package;
      default = pkgs.watson;
      defaultText = literalExpression "pkgs.watson";
      description = "Package providing the {command}`watson`.";
    };

    enableBashIntegration = mkEnableOption "watson's bash integration" // {
      default = true;
    };

    enableZshIntegration = mkEnableOption "watson's zsh integration" // {
      default = true;
    };

    enableFishIntegration = mkEnableOption "watson's fish integration" // {
      default = true;
    };

    settings = mkOption {
      type = iniFormat.type;
      default = { };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/watson/config` on Linux or
        {file}`$HOME/Library/Application Support/watson/config` on Darwin.

        See <https://github.com/TailorDev/Watson/blob/master/docs/user-guide/configuration.md>
        for an example configuration.
      '';
      example = literalExpression ''
        {
          backend = {
            url = "https://api.crick.fr";
            token = "yourapitoken";
          };

          options = {
            stop_on_start = true;
            stop_on_restart = false;
            date_format = "%Y.%m.%d";
            time_format = "%H:%M:%S%z";
            week_start = "monday";
            log_current = false;
            pager = true;
            report_current = false;
            reverse_log = true;
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file."${configDir}/watson/config" = mkIf (cfg.settings != { }) {
      source = iniFormat.generate "watson-config" cfg.settings;
    };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      source ${cfg.package}/share/bash-completion/completions/watson
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      source ${cfg.package}/share/zsh/site-functions/_watson
    '';

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      source ${cfg.package}/share/fish/vendor_completions.d/watson.fish
    '';
  };
}
