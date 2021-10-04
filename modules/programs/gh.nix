{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.gh;

in {
  meta.maintainers = [ maintainers.gerschtli ];

  options.programs.gh = {
    enable = mkEnableOption "GitHub CLI tool";

    aliases = mkOption {
      type = with types; attrsOf str;
      default = { };
      example = literalExample ''
        {
          co = "pr checkout";
          pv = "pr view";
        }
      '';
      description = ''
        Aliases that allow you to create nicknames for gh commands.
      '';
    };

    editor = mkOption {
      type = types.str;
      default = "";
      description = ''
        The editor that gh should run when creating issues, pull requests, etc.
        If blank, will refer to environment.
      '';
    };

    gitProtocol = mkOption {
      type = types.enum [ "https" "ssh" ];
      default = "https";
      description = ''
        The protocol to use when performing Git operations.
      '';
    };

    pager = mkOption {
      type = types.str;
      default = "";
      description = ''
        A pager program to send command output to, e.g. "less".
        Set the value to "cat" to disable the pager.
      '';
    };

    prompt = mkOption {
      type = types.enum [ "enabled" "disabled" ];
      default = "enabled";
      description = ''
        When to interactively prompt.
        This is a global config that cannot be overridden by hostname.
        Supported values: enabled, disabled.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.gh ];

    xdg.configFile."gh/config.yml".text = builtins.toJSON {
      inherit (cfg) aliases editor pager prompt;
      git_protocol = cfg.gitProtocol;
    };
  };
}
