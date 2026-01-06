{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe mkIf mkOption;
  cfg = config.programs.mise;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.hm.maintainers.pedorich-n ];

  imports =
    let
      mkRtxRemovedWarning =
        opt:
        (lib.mkRemovedOptionModule [ "programs" "rtx" opt ] ''
          The `rtx` package has been replaced by `mise`, please switch over to
          using the options under `programs.mise.*` instead.
        '');
    in
    [
      (lib.mkRemovedOptionModule [ "programs" "mise" "settings" ] ''
        mise no longer supports the separate `settings.toml` file for settings.
        Please define your settings with `programs.mise.globalConfig.settings`.
      '')
    ]
    ++ map mkRtxRemovedWarning [
      "enable"
      "package"
      "enableBashIntegration"
      "enableZshIntegration"
      "enableFishIntegration"
      "enableNushellIntegration"
      "settings"
    ];

  options = {
    programs.mise = {
      enable = lib.mkEnableOption "mise";

      package = lib.mkPackageOption pkgs "mise" { nullable = true; };

      enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

      enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

      enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

      enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };

      globalConfig = mkOption {
        inherit (tomlFormat) type;

        default = { };
        example = lib.literalExpression ''
          settings = {
            disable_tools = [ "node" ];
            experimental = true;
            verbose = false;
          };

          tool_alias = {
            node.versions = {
              my_custom_node = "20";
            };
          };

          tools = {
            node = "lts";
            python = ["3.10" "3.11"];
          };
        '';
        description = ''
          Config written to {file}`$XDG_CONFIG_HOME/mise/config.toml`.

          See <https://mise.jdx.dev/configuration.html> and
          <https://mise.jdx.dev/configuration/settings.html>
          for details on supported values.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    warnings =
      lib.optional
        (
          cfg.package == null
          && (
            cfg.enableBashIntegration
            || cfg.enableZshIntegration
            || cfg.enableFishIntegration
            || cfg.enableNushellIntegration
          )
        )
        ''
          You have enabled shell integration for `mise` but have not set `package`.

          The shell integration will not be added.
        '';

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = {
      "mise/config.toml" = mkIf (cfg.globalConfig != { }) {
        source = tomlFormat.generate "mise-config" cfg.globalConfig;
      };
    };

    programs = {
      bash.initExtra = mkIf (cfg.enableBashIntegration && cfg.package != null) ''
        eval "$(${getExe cfg.package} activate bash)"
      '';

      zsh.initContent = mkIf (cfg.enableZshIntegration && cfg.package != null) ''
        eval "$(${getExe cfg.package} activate zsh)"
      '';

      fish.interactiveShellInit = mkIf (cfg.enableFishIntegration && cfg.package != null) ''
        ${getExe cfg.package} activate fish | source
      '';

      nushell = mkIf (cfg.enableNushellIntegration && cfg.package != null) {
        extraConfig = ''
          use ${
            pkgs.runCommand "mise-nushell-config.nu" { } ''
              ${lib.getExe cfg.package} activate nu > $out
            ''
          }
        '';
      };
    };
  };
}
