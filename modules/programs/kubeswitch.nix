{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.kubeswitch;

  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [ lib.hm.maintainers.m0nsterrr ];

  options.programs.kubeswitch = {
    enable = lib.mkEnableOption "the kubectx for operators";

    commandName = lib.mkOption {
      type = lib.types.str;
      default = "kswitch";
      description = "The name of the command to use";
    };

    package = lib.mkPackageOption pkgs "kubeswitch" { };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    settings = lib.mkOption {
      type = yamlFormat.type;
      default = { };
      defaultText = lib.literalExpression "{ }";
      example = lib.literalExpression ''
        {
          kind = "SwitchConfig";
          kubeconfigName = "*.myconfig";
          kubeconfigStores = [
            {
              kind = "filesystem";
              kubeconfigName = "*.myconfig";
              paths = [
                "~/.kube/my-other-kubeconfigs/"
              ];
            }
          ];
          version = "v1alpha1";
        }
      '';
      description = ''
        Configuration written to
        {file}`~/.kube/switch-config.yaml`.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = [ cfg.package ];

        home.file = {
          ".kube/switch-config.yaml" = lib.mkIf (cfg.settings != { }) {
            source = yamlFormat.generate "kubeswitch-settings" cfg.settings;
          };
        };
      }

      (lib.mkIf cfg.enableBashIntegration (
        let
          shell_files = pkgs.runCommand "kubeswitch-shell-files" { buildInputs = [ cfg.package ]; } ''
            mkdir -p $out/share
            switcher init bash | sed 's/switch(/${cfg.commandName}(/' > $out/share/${cfg.commandName}_init.bash
            switcher --cmd ${cfg.commandName} completion bash > $out/share/${cfg.commandName}_completion.bash
          '';
        in
        {
          programs.bash.initExtra = ''
            source ${shell_files}/share/${cfg.commandName}_init.bash
            source ${shell_files}/share/${cfg.commandName}_completion.bash
          '';
        }
      ))

      (lib.mkIf cfg.enableFishIntegration (
        let
          shell_files = pkgs.runCommand "kubeswitch-shell-files" { buildInputs = [ cfg.package ]; } ''
            mkdir -p $out/share
            switcher init fish | sed 's/switch(/${cfg.commandName}(/' > $out/share/${cfg.commandName}_init.fish
            switcher --cmd ${cfg.commandName} completion fish > $out/share/${cfg.commandName}_completion.fish
          '';
        in
        {
          programs.fish.interactiveShellInit = ''
            source ${shell_files}/share/${cfg.commandName}_init.fish
            source ${shell_files}/share/${cfg.commandName}_completion.fish
          '';
        }
      ))

      (lib.mkIf cfg.enableZshIntegration (
        let
          shell_files = pkgs.runCommand "kubeswitch-shell-files" { buildInputs = [ cfg.package ]; } ''
            mkdir -p $out/share
            switcher init zsh | sed 's/switch(/${cfg.commandName}(/' > $out/share/${cfg.commandName}_init.zsh
            switcher --cmd ${cfg.commandName} completion zsh > $out/share/${cfg.commandName}_completion.zsh
          '';
        in
        {
          programs.zsh.initContent = ''
            source ${shell_files}/share/${cfg.commandName}_init.zsh
            source ${shell_files}/share/${cfg.commandName}_completion.zsh
          '';
        }
      ))
    ]
  );
}
