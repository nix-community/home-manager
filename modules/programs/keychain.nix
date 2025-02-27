{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.keychain;

  flags = cfg.extraFlags ++ optional (cfg.agents != [ ])
    "--agents ${concatStringsSep "," cfg.agents}"
    ++ optional (cfg.inheritType != null) "--inherit ${cfg.inheritType}";

  shellCommand =
    "${cfg.package}/bin/keychain --eval ${concatStringsSep " " flags} ${
      concatStringsSep " " cfg.keys
    }";

in {
  meta.maintainers = [ ];

  options.programs.keychain = {
    enable = mkEnableOption "keychain";

    package = mkOption {
      type = types.package;
      default = pkgs.keychain;
      defaultText = literalExpression "pkgs.keychain";
      description = ''
        Keychain package to install.
      '';
    };

    keys = mkOption {
      type = types.listOf types.str;
      default = [ "id_rsa" ];
      description = ''
        Keys to add to keychain.
      '';
    };

    agents = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Agents to add.
      '';
    };

    inheritType = mkOption {
      type =
        types.nullOr (types.enum [ "local" "any" "local-once" "any-once" ]);
      default = null;
      description = ''
        Inherit type to attempt from agent variables from the environment.
      '';
    };

    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [ "--quiet" ];
      description = ''
        Extra flags to pass to keychain.
      '';
    };

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration =
      lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };

    enableXsessionIntegration = mkOption {
      default = true;
      type = types.bool;
      visible = pkgs.stdenv.hostPlatform.isLinux;
      description = ''
        Whether to run keychain from your {file}`~/.xsession`.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(SHELL=bash ${shellCommand})"
    '';
    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
      SHELL=fish eval (${shellCommand})
    '';
    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      eval "$(SHELL=zsh ${shellCommand})"
    '';
    programs.nushell.extraConfig = mkIf cfg.enableNushellIntegration ''
      let keychain_shell_command = (SHELL=bash ${shellCommand}| parse -r '(\w+)=(.*); export \1' | transpose -ird)
      if not ($keychain_shell_command|is-empty) {
        $keychain_shell_command | load-env
      }
    '';
    xsession.initExtra = mkIf cfg.enableXsessionIntegration ''
      eval "$(SHELL=bash ${shellCommand})"
    '';
  };
}
