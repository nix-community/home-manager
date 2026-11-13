{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.fnox;
  tomlFormat = pkgs.formats.toml { };
  fnox = lib.getExe' cfg.package "fnox";

  shellIntegrationDescription = ''
    The integration automatically resolves and exports secrets when changing
    directories and before displaying a prompt.
  '';
in
{
  meta.maintainers = [ lib.hm.maintainers.o-az ];

  options.programs.fnox = {
    enable = lib.mkEnableOption "fnox, a flexible secret management tool";

    package = lib.mkPackageOption pkgs "fnox" { };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          env = "exec";
          if_missing = "warn";
          prompt_auth = false;
          daemon.enabled = false;
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/fnox/config.toml`.

        All values configured here are copied to the Nix store. Do not include
        plaintext secrets, private keys, authentication tokens, or other
        credentials. Use encrypted values or references to external secret
        providers instead.

        The generated file is immutable. Commands that modify fnox's global
        configuration cannot update it.

        See <https://github.com/jdx/fnox/blob/main/docs/reference/configuration.md>
        for available settings.
      '';
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption {
      inherit config;
      extraDescription = shellIntegrationDescription;
    };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption {
      inherit config;
      extraDescription = shellIntegrationDescription;
    };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption {
      inherit config;
      extraDescription = shellIntegrationDescription;
    };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption {
      inherit config;
      extraDescription = shellIntegrationDescription;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."fnox/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "fnox-config.toml" cfg.settings;
    };

    programs = {
      bash.initExtra = lib.mkIf cfg.enableBashIntegration ''
        eval "$(${fnox} activate bash)"
      '';

      fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration ''
        ${fnox} activate fish | source
      '';

      nushell.extraConfig = lib.mkIf cfg.enableNushellIntegration ''
        source ${
          pkgs.runCommand "fnox-nushell-integration.nu" { } ''
            ${fnox} activate nu > "$out"
          ''
        }
      '';

      zsh.initContent = lib.mkIf cfg.enableZshIntegration ''
        eval "$(${fnox} activate zsh)"
      '';
    };
  };
}
