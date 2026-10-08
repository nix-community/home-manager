{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe mkIf mkOption;
  cfg = config.programs.mise;
  globalConfigPath =
    if cfg.enableMutableConfig then "mise/conf.d/50-home-manager.toml" else "mise/config.toml";
  mutableConfigDir = "${config.xdg.configHome}/mise";
  mutableConfigPath = "${mutableConfigDir}/config.toml";
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
      (lib.mkRenamedOptionModule
        [ "programs" "mise" "settings" ]
        [ "programs" "mise" "globalConfig" "settings" ]
      )
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

      enableMutableConfig = mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
        description = ''
          Whether to leave {file}`$XDG_CONFIG_HOME/mise/config.toml` mutable
          so it can be updated by commands such as {command}`mise use --global`.

          When enabled, {option}`programs.mise.globalConfig` is written to
          {file}`$XDG_CONFIG_HOME/mise/conf.d/50-home-manager.toml` instead,
          leaving the main configuration file unmanaged. The numeric prefix
          gives user-managed fragments predictable ordering around the Home
          Manager fragment. An empty mutable configuration file is created
          because global Mise commands otherwise try to update an existing
          global fragment, including the read-only Home Manager fragment.

          Keep settings in the mutable file and
          {option}`programs.mise.globalConfig` disjoint. Mise may resolve
          conflicts between the global file and {file}`conf.d` differently
          depending on the current directory.

          Before disabling this option while
          {option}`programs.mise.globalConfig` is non-empty, remove or back up
          the mutable configuration file. Home Manager otherwise treats it as a
          file collision.
        '';
      };

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
          Global configuration written to
          {file}`$XDG_CONFIG_HOME/mise/config.toml`, or
          {file}`$XDG_CONFIG_HOME/mise/conf.d/50-home-manager.toml` when
          {option}`programs.mise.enableMutableConfig` is enabled.

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

    home.packages = lib.mkIf (cfg.package != null) [
      cfg.package
      # The generated completions call the `usage` CLI at completion time.
      pkgs.usage
    ];

    home.activation.miseMutableConfig = mkIf cfg.enableMutableConfig (
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        if [[ ! -e ${lib.escapeShellArg mutableConfigPath} && ! -L ${lib.escapeShellArg mutableConfigPath} ]]; then
          run mkdir -p ${lib.escapeShellArg mutableConfigDir}
          run touch ${lib.escapeShellArg mutableConfigPath}
        fi
      ''
    );

    xdg.configFile = {
      ${globalConfigPath} = mkIf (cfg.globalConfig != { }) {
        source = tomlFormat.generate "mise-config" cfg.globalConfig;
      };
    };

    programs = {
      bash.initExtra =
        let
          # TODO: Upstream to nixpkgs
          bashCompletion = pkgs.runCommand "mise-bash-completion.bash" { } ''
            ${getExe cfg.package} completion bash --include-bash-completion-lib > $out
          '';
        in
        mkIf (cfg.enableBashIntegration && cfg.package != null) ''
          eval "$(${getExe cfg.package} activate bash)"
          source ${bashCompletion}
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
