{ config, lib, pkgs, ... }:

with lib;
let

  cfg = config.programs.navi;

  yamlFormat = pkgs.formats.yaml { };

  configDir = if pkgs.stdenv.isDarwin then
    "Library/Application Support"
  else
    config.xdg.configHome;

in {
  meta.maintainers = [ ];

  options.programs.navi = {
    enable = mkEnableOption "Navi";

    package = mkOption {
      type = types.package;
      default = pkgs.navi;
      defaultText = literalExpression "pkgs.navi";
      description = "The package to use for the navi binary.";
    };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      example = literalExpression ''
        {
          cheats = {
            paths = [
              "~/cheats/"
            ];
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/navi/config.yaml` on Linux or
        {file}`$HOME/Library/Application Support/navi/config.yaml`
        on Darwin. See
        <https://github.com/denisidoro/navi/blob/master/docs/config_file.md>
        for more information.
      '';
    };

    enableBashIntegration = mkEnableOption "Bash integration" // {
      default = true;
    };

    enableZshIntegration = mkEnableOption "Zsh integration" // {
      default = true;
    };

    enableFishIntegration = mkEnableOption "Fish integration" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
        eval "$(${cfg.package}/bin/navi widget bash)"
      fi
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      if [[ $options[zle] = on ]]; then
        eval "$(${cfg.package}/bin/navi widget zsh)"
      fi
    '';

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      ${cfg.package}/bin/navi widget fish | source
    '';

    home.file."${configDir}/navi/config.yaml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "navi-config" cfg.settings;
    };
  };
}
