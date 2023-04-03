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

    enableFishIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Atuin's Fish integration.
        </para><para>
        If enabled, this will bind the up-arrow key to open the Atuin history.
      '';
    };

    flags = mkOption {
      default = [ ];
      type = types.listOf types.str;
      example = [ "--disable-up-arrow" "--disable-ctrl-r" ];
      description = ''
        Flags to append to the shell hook.
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
        <filename>$XDG_CONFIG_HOME/atuin/config.toml</filename>.
        </para><para>
        See <link xlink:href="https://github.com/ellie/atuin/blob/main/docs/config.md" /> for the full list
        of options.
      '';
    };

    enableNushellIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Nushell integration.
      '';
    };
  };

  config = let flagsStr = escapeShellArgs cfg.flags;
  in mkIf cfg.enable {

    # Always add the configured `atuin` package.
    home.packages = [ cfg.package ];

    # If there are user-provided settings, generate the config file.
    xdg.configFile."atuin/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "atuin-config" cfg.settings;
    };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
        source "${pkgs.bash-preexec}/share/bash/bash-preexec.sh"
        eval "$(${cfg.package}/bin/atuin init bash ${flagsStr})"
      fi
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      if [[ $options[zle] = on ]]; then
        eval "$(${cfg.package}/bin/atuin init zsh ${flagsStr})"
      fi
    '';

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
      ${cfg.package}/bin/atuin init fish ${flagsStr} | source
    '';

    programs.nushell = mkIf cfg.enableNushellIntegration {
      extraEnv = ''
        let atuin_cache = "${config.xdg.cacheHome}/atuin"
        if not ($atuin_cache | path exists) {
          mkdir $atuin_cache
        }
        ${cfg.package}/bin/atuin init nu | save --force ${config.xdg.cacheHome}/atuin/init.nu
      '';
      extraConfig = ''
        source ${config.xdg.cacheHome}/atuin/init.nu
      '';
    };
  };
}
