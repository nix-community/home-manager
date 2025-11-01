{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf types;

  cfg = config.programs.lazygit;

  yamlFormat = pkgs.formats.yaml { };

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

in
{
  meta.maintainers = [
    lib.hm.maintainers.kalhauge
    lib.maintainers.khaneliman
  ];

  options.programs.lazygit = {
    enable = lib.mkEnableOption "lazygit, a simple terminal UI for git commands";

    package = lib.mkPackageOption pkgs "lazygit" { nullable = true; };

    settings = lib.mkOption {
      type = yamlFormat.type;
      default = { };
      defaultText = lib.literalExpression "{ }";
      example = lib.literalExpression ''
        {
          gui.theme = {
            lightTheme = true;
            activeBorderColor = [ "blue" "bold" ];
            inactiveBorderColor = [ "black" ];
            selectedLineBgColor = [ "default" ];
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/lazygit/config.yml`
        on Linux or on Darwin if [](#opt-xdg.enable) is set, otherwise
        {file}`~/Library/Application Support/lazygit/config.yml`.
        See
        <https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md>
        for supported values.
      '';
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    shellWrapperName = lib.mkOption {
      type = types.str;
      default = "lg";
      example = "lg";
      description = ''
        Name of the shell wrapper to be called.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    home.file."Library/Application Support/lazygit/config.yml" =
      mkIf (cfg.settings != { } && (isDarwin && !config.xdg.enable))
        {
          source = yamlFormat.generate "lazygit-config" cfg.settings;
        };

    xdg.configFile."lazygit/config.yml" =
      mkIf (cfg.settings != { } && !(isDarwin && !config.xdg.enable))
        {
          source = yamlFormat.generate "lazygit-config" cfg.settings;
        };

    programs =
      let
        lazygitNewDirFilePath =
          if config.home.preferXdgDirectories then
            "${config.xdg.cacheHome}/lazygit/newdir"
          else
            "~/.lazygit/newdir";

        bashIntegration = ''
          ${cfg.shellWrapperName}() {
              export LAZYGIT_NEW_DIR_FILE=${lazygitNewDirFilePath}
              lazygit "$@"
              if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
                cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
                rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
              fi
          }
        '';

        fishIntegration = ''
          function ${cfg.shellWrapperName}
            set -x LAZYGIT_NEW_DIR_FILE ${lazygitNewDirFilePath}
            command lazygit $argv
            if test -f $LAZYGIT_NEW_DIR_FILE
              cd (cat $LAZYGIT_NEW_DIR_FILE)
              rm -f $LAZYGIT_NEW_DIR_FILE
            end
          end
        '';

        nushellIntegration = ''
          def --env ${cfg.shellWrapperName} [...args] {
            $env.LAZYGIT_NEW_DIR_FILE = "${lazygitNewDirFilePath}" | path expand
            lazygit ...$args
            if ($env.LAZYGIT_NEW_DIR_FILE | path exists) {
              cd (open $env.LAZYGIT_NEW_DIR_FILE)
              rm -f $env.LAZYGIT_NEW_DIR_FILE
            }
          }
        '';
      in
      {
        bash.initExtra = mkIf cfg.enableBashIntegration bashIntegration;

        zsh.initContent = mkIf cfg.enableZshIntegration bashIntegration;

        fish.functions.${cfg.shellWrapperName} = mkIf cfg.enableFishIntegration fishIntegration;

        nushell.extraConfig = mkIf cfg.enableNushellIntegration nushellIntegration;
      };
  };
}
