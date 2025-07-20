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
  meta.maintainers = [ lib.maintainers.m0nsterrr ];

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
      example = {
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
      };
      description = ''
        Configuration written to
        {file}`~/.kube/switch-config.yaml`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [ cfg.package ];

      file.".kube/switch-config.yaml" = lib.mkIf (cfg.settings != { }) {
        source = yamlFormat.generate "kubeswitch-settings" cfg.settings;
      };
    };

    programs =
      let
        generateKubeswitchShellFiles =
          shell:
          pkgs.runCommand "kubeswitch-${cfg.commandName}-shell-files-for-${shell}"
            {
              nativeBuildInputs = [ cfg.package ];
            }
            ''
              mkdir -p $out/share
              switcher init "${shell}" | sed "s/switch(/${cfg.commandName}(/" > "$out/share/${cfg.commandName}_init.${shell}"
              switcher --cmd "${cfg.commandName}" completion "${shell}" > "$out/share/${cfg.commandName}_completion.${shell}"
            '';
      in
      {
        bash.initExtra =
          let
            kubeswitchBashFiles = generateKubeswitchShellFiles "bash";
          in
          lib.mkIf cfg.enableBashIntegration ''
            source ${kubeswitchBashFiles}/share/${cfg.commandName}_init.bash
            source ${kubeswitchBashFiles}/share/${cfg.commandName}_completion.bash
          '';

        fish.interactiveShellInit =
          let
            shell_files =
              pkgs.runCommand "kubeswitch-${cfg.commandName}-shell-files-for-fish"
                { buildInputs = [ cfg.package ]; }
                ''
                  mkdir -p $out/share
                  switcher init fish | sed "s/kubeswitch/${cfg.commandName}/" > $out/share/${cfg.commandName}_init.fish
                  switcher --cmd ${cfg.commandName} completion fish > $out/share/${cfg.commandName}_completion.fish
                '';
          in
          lib.mkIf cfg.enableFishIntegration ''
            source ${shell_files}/share/${cfg.commandName}_init.fish
            source ${shell_files}/share/${cfg.commandName}_completion.fish
          '';

        zsh.initContent =
          let
            kubeswitchZshFiles = generateKubeswitchShellFiles "zsh";
          in
          lib.mkIf cfg.enableZshIntegration ''
            source ${kubeswitchZshFiles}/share/${cfg.commandName}_init.zsh
            source ${kubeswitchZshFiles}/share/${cfg.commandName}_completion.zsh
          '';
      };
  };
}
