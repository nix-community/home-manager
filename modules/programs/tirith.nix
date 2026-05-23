{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.tirith;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = with lib.maintainers; [ malik ];

  options.programs.tirith = {
    enable = lib.mkEnableOption "Tirith, a shell security monitor";

    package = lib.mkPackageOption pkgs "tirith" { };

    allowlist = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      apply = builtins.filter (s: s != "");
      example = [
        "localhost"
      ];
      description = ''
        List of allowed domains that bypass Tirith analysis.
        Written to `$XDG_CONFIG_HOME/tirith/allowlist`.
      '';
    };

    policy = lib.mkOption {
      type = yamlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          version = 1;
          fail_mode = "open";
          allow_bypass = true;
          severity_overrides = {
            docker_untrusted_registry = "critical";
          };
        }
      '';
      description = ''
        Tirith policy configuration.
        Written to `$XDG_CONFIG_HOME/tirith/policy.yaml`.

        See <https://github.com/sheeki03/tirith/blob/main/docs/cookbook.md>
        for policy examples.
      '';
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };
    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };
    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "tirith/allowlist" = lib.mkIf (cfg.allowlist != [ ]) {
        text = (lib.concatStringsSep "\n" cfg.allowlist) + "\n";
      };

      "tirith/policy.yaml" = lib.mkIf (cfg.policy != { }) {
        source = yamlFormat.generate "tirith-policy.yaml" cfg.policy;
      };
    };

    programs.bash.initExtra = lib.mkIf cfg.enableBashIntegration ''
      eval "$(${lib.getExe cfg.package} init --shell bash)"
    '';

    programs.fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration ''
      ${lib.getExe cfg.package} init --shell fish | source
    '';

    programs.zsh.initExtra = lib.mkIf cfg.enableZshIntegration ''
      eval "$(${lib.getExe cfg.package} init --shell zsh)"
    '';
  };
}
