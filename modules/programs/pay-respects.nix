{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.pay-respects;

  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.maintainers.ALameLlama ];

  options.programs.pay-respects = {
    enable = lib.mkEnableOption "pay-respects";

    package = lib.mkPackageOption pkgs "pay-respects" { };

    options = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "--alias" ];
      example = [
        "--alias"
        "f"
      ];
      description = ''
        List of options to pass to pay-respects <shell>.
      '';
    };

    rules = lib.mkOption {
      type = lib.types.attrsOf tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          cargo = {
            command = "cargo";
            match_err = [
              {
                pattern = [ "run `cargo init` to initialize a new rust project" ];
                suggest = [ "cargo init" ];
              }
            ];
          };

          _PR_GENERAL = {
            match_err = [
              {
                pattern = [ "permission denied" ];
                suggest = [
                  "#[executable(sudo), !cmd_contains(sudo)]\nsudo {{command}}"
                ];
              }
            ];
          };
        }
      '';
      description = ''
        Runtime rule files written to
        {file}`$XDG_CONFIG_HOME/pay-respects/rules/<name>.toml`.

        Attribute names map to filenames. For example, setting `rules.cargo = { ... };`
        creates {file}`$XDG_CONFIG_HOME/pay-respects/rules/cargo.toml`.
        The filename must match the command name, except for `_PR_GENERAL`.

        See <https://github.com/iffse/pay-respects/blob/main/rules.md>
        for runtime rule syntax and behavior.

        Note that these rules are only applied when the runtime-rules module is
        available to `pay-respects`.
      '';
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = lib.mapAttrs' (
      name: rule:
      lib.nameValuePair "pay-respects/rules/${name}.toml" {
        source = tomlFormat.generate "pay-respects-rule-${name}.toml" rule;
      }
    ) cfg.rules;

    programs =
      let
        payRespectsCmd = lib.getExe cfg.package;
        cfgOptions = lib.concatStringsSep " " cfg.options;
      in
      {
        bash.initExtra = lib.mkIf cfg.enableBashIntegration ''
          eval "$(${payRespectsCmd} bash ${cfgOptions})"
        '';

        zsh.initContent = lib.mkIf cfg.enableZshIntegration ''
          eval "$(${payRespectsCmd} zsh ${cfgOptions})"
        '';

        fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration ''
          ${payRespectsCmd} fish ${cfgOptions} | source
        '';

        nushell.extraConfig = lib.mkIf cfg.enableNushellIntegration ''
          source ${
            pkgs.runCommand "pay-respects-nushell-config.nu" { } ''
              ${payRespectsCmd} nushell ${cfgOptions} >> "$out"
            ''
          }
        '';
      };
  };
}
