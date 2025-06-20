{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;

  cfg = config.programs.kubecolor;
  yamlFormat = pkgs.formats.yaml { };
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

in
{
  meta.maintainers = with lib.maintainers; [ ajgon ];

  options.programs.kubecolor = {
    enable = lib.mkEnableOption "kubecolor - Colorize your kubectl output";

    package = lib.mkPackageOption pkgs "kubecolor" { };

    enableAlias = mkOption {
      type = types.bool;
      default = false;
      description = ''
        When set to true, it will create an alias for kubectl pointing to
        kubecolor, thus making kubecolor the default kubectl client.
      '';
    };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      example = lib.literalExpression ''
        kubectl = lib.getExe pkgs.kubectl
        preset = "dark";
        paging = "auto";
      '';
      description = ''
        Configuration written to {file}`~/.kube/color.yaml` (Linux)
        or {file}`Library/Application Support/kube/color.yaml` (Darwin).
        See <https://kubecolor.github.io/reference/config/> for supported
        values.
      '';
    };
  };

  config =
    let
      preferXdgDirectories = config.home.preferXdgDirectories && (!isDarwin || config.xdg.enable);

      # https://github.com/kubecolor/kubecolor/pull/145
      configPathSuffix =
        if
          cfg.package.pname == "kubecolor"
          && lib.strings.toInt (lib.versions.major cfg.package.version) == 0
          && lib.strings.toInt (lib.versions.minor cfg.package.version) < 4
        then
          "kube/"
        else
          "kube/color.yaml";

    in
    mkIf cfg.enable {
      warnings = lib.optional (cfg.package == null && cfg.plugins != [ ]) ''
        You have configured `enableAlias` for `kubecolor` but have not set `package`.

        The alias will not be created.
      '';

      home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      home.sessionVariables =
        if preferXdgDirectories then
          {
            KUBECOLOR_CONFIG = "${config.xdg.configHome}/${configPathSuffix}";
          }
        else if isDarwin then
          {
            KUBECOLOR_CONFIG = "${config.home.homeDirectory}/Library/Application Support/${configPathSuffix}";
          }
        else
          { };

      xdg.configFile = mkIf preferXdgDirectories {
        "kube/color.yaml" = mkIf (cfg.settings != { }) {
          source = yamlFormat.generate "kubecolor-settings" cfg.settings;
        };
      };

      home.file = mkIf (!preferXdgDirectories) {
        "Library/Application Support/kube/color.yaml" = mkIf (isDarwin && cfg.settings != { }) {
          source = yamlFormat.generate "kubecolor-settings" cfg.settings;
        };
        ".kube/color.yaml" = mkIf (!isDarwin && cfg.settings != { }) {
          source = yamlFormat.generate "kubecolor-settings" cfg.settings;
        };
      };

      home.shellAliases = lib.mkIf (cfg.enableAlias && (cfg.package != null)) {
        kubectl = lib.getExe cfg.package;
        oc = lib.mkIf (builtins.elem pkgs.openshift config.home.packages) "env KUBECTL_COMMAND=${lib.getExe pkgs.openshift} ${lib.getExe cfg.package}";
      };

      programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration "compdef kubecolor=kubectl";
    };
}
