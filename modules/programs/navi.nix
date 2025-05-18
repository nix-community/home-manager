{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.programs.navi;

  yamlFormat = pkgs.formats.yaml { };

  configDir =
    if pkgs.stdenv.isDarwin && !config.xdg.enable then
      "Library/Application Support"
    else
      config.xdg.configHome;

in
{
  meta.maintainers = [ ];

  options.programs.navi = {
    enable = lib.mkEnableOption "Navi";

    package = lib.mkPackageOption pkgs "navi" { };

    settings = lib.mkOption {
      type = yamlFormat.type;
      default = { };
      example = lib.literalExpression ''
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

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
        eval "$(${cfg.package}/bin/navi widget bash)"
      fi
    '';

    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
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
