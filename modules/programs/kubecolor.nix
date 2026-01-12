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
      preferXdgDirectories =
        config.home.preferXdgDirectories && (!pkgs.stdenv.hostPlatform.isDarwin || config.xdg.enable);
      configDir =
        if preferXdgDirectories then
          "${config.xdg.configHome}/kube"
        else if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/kube"
        else
          ".kube";

      # https://github.com/kubecolor/kubecolor/pull/145
      configPathSuffix = lib.optionalString (
        cfg.package.pname == "kubecolor" && lib.versionAtLeast (lib.getVersion cfg.package) "0.4"
      ) "color.yaml";

    in
    mkIf cfg.enable {
      warnings = lib.optional (cfg.package == null && cfg.plugins != [ ]) ''
        You have configured `enableAlias` for `kubecolor` but have not set `package`.

        The alias will not be created.
      '';

      home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      home.sessionVariables.KUBECOLOR_CONFIG = "${configDir}/${configPathSuffix}";

      home.file."${configDir}/color.yaml" = mkIf (cfg.settings != { }) {
        source = yamlFormat.generate "kubecolor-settings" cfg.settings;
      };

      home.shellAliases = lib.mkIf (cfg.enableAlias && (cfg.package != null)) {
        kubectl = lib.getExe cfg.package;
        oc = lib.mkIf (builtins.elem pkgs.openshift config.home.packages) "env KUBECTL_COMMAND=${lib.getExe pkgs.openshift} ${lib.getExe cfg.package}";
      };

      programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration "compdef kubecolor=kubectl";
    };
}
