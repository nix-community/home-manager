{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.keychain;

  flags = cfg.extraFlags
    ++ optional (cfg.agents != []) "--agents ${concatStringsSep "," cfg.agents}"
    ++ optional (cfg.inheritType != null) "--inherit ${cfg.inheritType}";

  shellCommand = ''
    eval "$(${cfg.package}/bin/keychain --eval ${concatStringsSep " " flags} ${concatStringsSep " " cfg.keys})"
  '';

in

{
  meta.maintainers = [ maintainers.marsam ];

  options.programs.keychain = {
    enable = mkEnableOption "keychain";

    package = mkOption {
      type = types.package;
      default = pkgs.keychain;
      defaultText = literalExample "pkgs.keychain";
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
      default = [];
      description = ''
        Agents to add.
      '';
    };

    inheritType = mkOption {
      type = types.nullOr (types.enum ["local" "any" "local-once" "any-once"]);
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

    enableBashIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Bash integration.
      '';
    };

    enableZshIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Zsh integration.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    programs.bash.initExtra = mkIf cfg.enableBashIntegration shellCommand;
    programs.zsh.initExtra = mkIf cfg.enableZshIntegration shellCommand;
  };
}
