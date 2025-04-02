{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf;

  cfg = config.programs.oh-my-posh;

  jsonFormat = pkgs.formats.json { };

  configArgument = if cfg.settings != { } then
    "--config ${config.xdg.configHome}/oh-my-posh/config.json"
  else if cfg.useTheme != null then
    "--config ${cfg.package}/share/oh-my-posh/themes/${cfg.useTheme}.omp.json"
  else
    "";

in {
  meta.maintainers = [ lib.maintainers.arjan-s ];

  options.programs.oh-my-posh = {
    enable =
      lib.mkEnableOption "oh-my-posh, a prompt theme engine for any shell";

    package = lib.mkPackageOption pkgs "oh-my-posh" { };

    settings = lib.mkOption {
      type = jsonFormat.type;
      default = { };
      example = lib.literalExpression ''
        builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile "''${pkgs.oh-my-posh}/share/oh-my-posh/themes/space.omp.json"))'';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/oh-my-posh/config.json`. See
        <https://ohmyposh.dev/docs/configuration/overview>
        for details. The `useTheme` option is ignored when this
        option is used.
      '';
    };

    useTheme = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Use one of the official themes. This should be a name from this list:
        <https://ohmyposh.dev/docs/themes>. Because a theme
        is essentially a configuration file, this option is not used when a
        `configFile` is set.
      '';
    };

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration =
      lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."oh-my-posh/config.json" = mkIf (cfg.settings != { }) {
      source = jsonFormat.generate "oh-my-posh-settings" cfg.settings;
    };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(${lib.getExe cfg.package} init bash ${configArgument})"
    '';

    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
      eval "$(${lib.getExe cfg.package} init zsh ${configArgument})"
    '';

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      ${lib.getExe cfg.package} init fish ${configArgument} | source
    '';

    programs.nushell = mkIf cfg.enableNushellIntegration {
      extraConfig = ''
        source ${
          pkgs.runCommand "oh-my-posh-nushell-config.nu" { } ''
            ${
              lib.getExe cfg.package
            } init nu ${configArgument} --print >> "$out"
          ''
        }
      '';
    };
  };
}
