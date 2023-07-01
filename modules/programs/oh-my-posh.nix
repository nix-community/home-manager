{ config, lib, pkgs, ... }:

with lib;
let

  cfg = config.programs.oh-my-posh;

  jsonFormat = pkgs.formats.json { };

  configArgument = if cfg.settings != { } then
    "--config ${config.xdg.configHome}/oh-my-posh/config.json"
  else if cfg.useTheme != null then
    "--config ${cfg.package}/share/oh-my-posh/themes/${cfg.useTheme}.omp.json"
  else
    "";

in {
  meta.maintainers = [ maintainers.arjan-s ];

  options.programs.oh-my-posh = {
    enable = mkEnableOption "oh-my-posh, a prompt theme engine for any shell";

    package = mkPackageOption pkgs "oh-my-posh" { };

    settings = mkOption {
      type = jsonFormat.type;
      default = { };
      example = literalExpression ''
        builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile "''${pkgs.oh-my-posh}/share/oh-my-posh/themes/space.omp.json"))'';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/oh-my-posh/config.json`. See
        <https://ohmyposh.dev/docs/configuration/overview>
        for details. The `useTheme` option is ignored when this
        option is used.
      '';
    };

    useTheme = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Use one of the official themes. This should be a name from this list:
        <https://ohmyposh.dev/docs/themes>. Because a theme
        is essentially a configuration file, this option is not used when a
        `configFile` is set.
      '';
    };

    enableBashIntegration = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable Bash integration.
      '';
    };

    enableZshIntegration = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable Zsh integration.
      '';
    };

    enableFishIntegration = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable Fish integration.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."oh-my-posh/config.json" = mkIf (cfg.settings != { }) {
      source = jsonFormat.generate "oh-my-posh-settings" cfg.settings;
    };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(${cfg.package}/bin/oh-my-posh init bash ${configArgument})"
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      eval "$(${cfg.package}/bin/oh-my-posh init zsh ${configArgument})"
    '';

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      ${cfg.package}/bin/oh-my-posh init fish ${configArgument} | source
    '';
  };
}
