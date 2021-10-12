{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.programs.atuin;

  tomlFormat = pkgs.formats.toml { };

in {
  meta.maintainers = [ maintainers.hawkw ];

  options.programs.atuin = {
    enable = mkEnableOption "atuin";

    package = mkOption {
      type = types.package;
      default = pkgs.atuin;
      defaultText = literalExpression "pkgs.atuin";
      description = "The package to use for atuin.";
    };

    enableBashIntegration = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable Atuin's Bash integration. This will bind
        <literal>ctrl-r</literal> to open the Atuin history.
      '';
    };

    enableZshIntegration = mkEnableOption "Zsh integration" // {
      default = true;
      description = ''
        Whether to enable Atuin's Zsh integration.
        </para><para>
        If enabled, this will bind <literal>ctrl-r</literal> and the up-arrow
        key to open the Atuin history.
      '';
    };

    settings = mkOption {
      type = with types;
        let
          prim = oneOf [ bool int str ];
          primOrPrimAttrs = either prim (attrsOf prim);
          entry = either prim (listOf primOrPrimAttrs);
          entryOrAttrsOf = t: either entry (attrsOf t);
          entries = entryOrAttrsOf (entryOrAttrsOf entry);
        in attrsOf entries // { description = "Atuin configuration"; };
      default = { };
      example = literalExpression ''
        {
          auto_sync = true;
          sync_frequency = "5m";
          sync_address = "https://api.atuin.sh";
          search_mode = "prefix";
        }
      '';
      description = ''
        Configuration written to
        <filename>~/.config/atuin/config.toml</filename>.
        </para><para>
        See <link xlink:href="https://github.com/ellie/atuin/blob/main/docs/config.md" /> for the full list
        of options.
      '';
    };
  };

  config = mkIf cfg.enable {

    # Always add the configured `atuin` package.
    home.packages = [ cfg.package ];

    # If there are user-provided settings, generate the config file.
    xdg.configFile."atuin/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "atuin-config" cfg.settings;
    };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      source "${pkgs.bash-preexec}/share/bash/bash-preexec.sh"
      eval "$(${cfg.package}/bin/atuin init bash)"
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      eval "$(${cfg.package}/bin/atuin init zsh)"
    '';
  };
}
