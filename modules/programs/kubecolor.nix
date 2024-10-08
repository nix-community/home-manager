{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.kubecolor;
  yamlFormat = pkgs.formats.yaml { };
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

in {
  meta.maintainers = with maintainers; [ ajgon ];

  options.programs.kubecolor = {
    enable = mkEnableOption "kubecolor - Colorize your kubectl output";

    package = mkPackageOption pkgs "kubecolor" { };

    overrideKubectl = mkOption {
      type = types.bool;
      default = false;
      description = ''
        When set to true, it will create an alias for kubectl pointing to kubecolor,
        thus making kubecolor default kubectl client.
      '';
    };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/kube/color.yaml` (linux)
        or {file}`Library/Application Support/kube/color.yaml` (darwin), See
        <https://kubecolor.github.io/reference/config/> for supported values.
      '';
      example = literalExpression ''
        kubectl = lib.getExe kubectl
        preset = "dark";
        paging = "auto";
      '';
    };
  };

  config = let
    enableXdgConfig = !isDarwin || config.xdg.enable;

    # https://github.com/kubecolor/kubecolor/pull/145
    configPathSuffix = if cfg.package.pname == "kubecolor"
    && lib.strings.toInt (lib.versions.major cfg.package.version) == 0
    && lib.strings.toInt (lib.versions.minor cfg.package.version) < 4 then
      "kube/"
    else
      "kube/color.yaml";

  in mkIf cfg.enable {
    home.enableNixpkgsReleaseCheck = false;

    home.packages = [ cfg.package ];

    home.sessionVariables.KUBECOLOR_CONFIG = if enableXdgConfig then
      "${config.xdg.configHome}/${configPathSuffix}"
    else
      "${config.home.homeDirectory}/Library/Application Support/${configPathSuffix}";

    xdg.configFile = mkIf enableXdgConfig {
      "kube/color.yaml" = mkIf (cfg.settings != { }) {
        source = yamlFormat.generate "kubecolor-settings" cfg.settings;
      };
    };

    home.file = mkIf (!enableXdgConfig) {
      "Library/Application Support/kube/color.yaml" =
        mkIf (cfg.settings != { }) {
          source = yamlFormat.generate "kubecolor-settings" cfg.settings;
        };
    };

    home.shellAliases =
      lib.mkIf cfg.overrideKubectl { kubectl = lib.getExe cfg.package; };
  };
}
