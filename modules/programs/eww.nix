{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.eww;
  ewwCmd = "${cfg.package}/bin/eww";

in {
  meta.maintainers = [ hm.maintainers.mainrs ];

  options.programs.eww = {
    enable = mkEnableOption "eww";

    package = mkOption {
      type = types.package;
      default = pkgs.eww;
      defaultText = literalExpression "pkgs.eww";
      example = literalExpression "pkgs.eww";
      description = ''
        The eww package to install.
      '';
    };

    configDir = mkOption {
      type = types.path;
      example = literalExpression "./eww-config-dir";
      description = ''
        The directory that gets symlinked to
        {file}`$XDG_CONFIG_HOME/eww`.
      '';
    };

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."eww".source = cfg.configDir;

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      if [[ $TERM != "dumb" ]]; then
        eval "$(${ewwCmd} shell-completions --shell bash)"
      fi
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      if [[ $TERM != "dumb" ]]; then
        eval "$(${ewwCmd} shell-completions --shell zsh)"
      fi
    '';

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
      if test "$TERM" != "dumb"
        eval "$(${ewwCmd} shell-completions --shell fish)"
      end
    '';
  };
}
