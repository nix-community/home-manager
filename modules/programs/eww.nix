{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.programs.eww;
in
{
  meta.maintainers = [ lib.hm.maintainers.mainrs ];

  options.programs.eww = {
    enable = lib.mkEnableOption "eww";

    package = lib.mkPackageOption pkgs "eww" { };

    configDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression "./eww-config-dir";
      description = ''
        The directory that gets symlinked to
        {file}`$XDG_CONFIG_HOME/eww`.
      '';
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config =
    let
      ewwCmd = lib.getExe cfg.package;
    in
    mkIf cfg.enable {
      home.packages = [ cfg.package ];
      xdg = mkIf (cfg.configDir != null) { configFile."eww".source = cfg.configDir; };

      programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
        if [[ $TERM != "dumb" ]]; then
          eval "$(${ewwCmd} shell-completions --shell bash)"
        fi
      '';

      programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
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
