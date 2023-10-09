{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.rtx;
  tomlFormat = pkgs.formats.toml { };
in {
  meta.maintainers = [ hm.maintainers.pedorich-n ];

  options = {
    programs.rtx = {
      enable = mkEnableOption "RTX. Runtime Executor (asdf Rust clone)";

      package = mkPackageOption pkgs "rtx" { };

      enableBashIntegration = mkEnableOption "Bash Integration" // {
        default = true;
      };

      enableZshIntegration = mkEnableOption "Zsh Integration" // {
        default = true;
      };

      enableFishIntegration = mkEnableOption "Fish Integration" // {
        default = true;
      };

      settings = mkOption {
        type = tomlFormat.type;
        default = { };
        example = literalExpression ''
          tools = {
            node = "lts";
            python = ["3.10" "3.11"];
          };

          settings = {
            verbose = false;
            experimental = false;
          };
        '';
        description = ''
          Settings written to {file}`$XDG_CONFIG_HOME/rtx/config.toml`.

          See <https://github.com/jdxcode/rtx#global-config-configrtxconfigtoml>
          for details on supported values.

          ::: {.warning}
          Modifying the `tools` section doesn't make RTX install them.
          You have to manually run `rtx install` to install the tools.
          :::
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."rtx/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "rtx-settings" cfg.settings;
    };

    programs = {
      bash.initExtra = mkIf cfg.enableBashIntegration ''
        eval "$(${getExe cfg.package} activate bash)"
      '';

      zsh.initExtra = mkIf cfg.enableZshIntegration ''
        eval "$(${getExe cfg.package} activate zsh)"
      '';

      fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
        ${getExe cfg.package} activate fish | source
      '';
    };
  };
}
