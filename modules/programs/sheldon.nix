{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.sheldon;
  tomlFormat = pkgs.formats.toml { };
  sheldonCmd = "${config.home.profileDirectory}/bin/sheldon";
in {
  meta.maintainers = with maintainers; [ Kyure-A mainrs ];

  options.programs.sheldon = {
    enable = mkEnableOption "sheldon";

    package = mkOption {
      type = types.package;
      default = pkgs.sheldon;
      defaultText = literalExpression "pkgs.sheldon";
      description = "The package to use for the sheldon binary.";
    };

    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      description = "";
      example = literalExpression "";
    };

    enableZshCompletions = mkEnableOption "Zsh completions" // {
      default = true;
    };

    enableBashCompletions = mkEnableOption "Bash completions" // {
      default = true;
    };

    enableFishCompletions = mkEnableOption "Fish completions" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."sheldon/plugins.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "sheldon-config" cfg.settings;
    };

    programs.bash.initExtra = ''
      ${optionalString (cfg.settings != { }) ''
        eval "$(sheldon source)"
      ''}
      ${optionalString cfg.enableBashCompletions ''
        if [[ $TERM != "dumb" ]]; then
           eval "$(${sheldonCmd} completions --shell=bash)"
        fi
      ''}
    '';

    programs.zsh.initExtra = ''
      ${optionalString (cfg.settings != { }) ''
        eval "$(sheldon source)"
      ''}
      ${optionalString cfg.enableZshCompletions ''
        if [[ $TERM != "dumb" ]]; then
           eval "$(${sheldonCmd} completions --shell=zsh)"
        fi
      ''}
    '';

    programs.fish.interactiveShellInit = ''
      ${optionalString (cfg.settings != { }) ''
        eval "$(sheldon source)"
      ''}
      ${optionalString cfg.enableFishCompletions ''
        if test "$TERM" != "dumb"
           eval "$(${sheldonCmd} completions --shell=fish)"
        end
      ''}
    '';
  };
}
