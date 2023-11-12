{ pkgs, config, lib, ... }:
let
  inherit (lib)
    mkIf mkEnableOption mkPackageOption mkOption literalExpression types;
  cfg = config.programs.hishtory;
  shellConfPath = "${cfg.package.outPath}/share/hishtory";
in {
  meta.maintainers = [ lib.maintainers.willemml ];

  config.home.packages = mkIf cfg.enable [ cfg.package ];

  config.programs.bash.bashrcExtra =
    mkIf cfg.enableBashIntegration "source '${shellConfPath}/config.bash'";
  config.programs.fish.loginShellInit =
    mkIf cfg.enableFishIntegration "source '${shellConfPath}/config.fish'";
  config.programs.zsh.initExtra =
    mkIf cfg.enableZshIntegration "source '${shellConfPath}/config.zsh'";

  config.home.activation.hishtoryActivation = let
    hishtory = "${pkgs.hishtory.out}/bin/hishtory";
    config-cmd = cmd: name: value:
      if (value != "" && value != [ ] && value != null) then
        "${hishtory} ${cmd} ${name} ${toString value}"
      else
        "";
    config-set = config-cmd "config-set";
  in mkIf (cfg.enable && cfg.enableConfig)
  (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${hishtory} config-get custom-columns | cut -f1 -d ":" | xargs -I {} ${hishtory} config-delete custom-columns {}

    ${config-cmd "config-set" "displayed-columns" "''"}
    ${toString (lib.forEach cfg.settings.displayed-columns (value:
      (config-cmd "config-add" "displayed-columns" ''
        '${value}'
      '')))}
    ${config-cmd "config-delete" "displayed-columns" "''"}

    ${config-set "enable-control-r" cfg.settings.enable-control-r}
    ${config-set "beta-mode" cfg.settings.beta-mode}
    ${config-set "timestamp-format" "'${cfg.settings.timestamp-format}'"}
    ${config-set "filter-duplicate-commands"
    cfg.settings.filter-duplicate-commands}

    ${(toString (lib.attrsets.mapAttrsToList (name: value: ''
      ${hishtory} config-add custom-columns ${name} '${value}'
    '') cfg.settings.custom-columns))}
  '');

  options.programs.hishtory = let
    trueFalseOption = desc:
      mkOption {
        type = types.bool;
        example = true;
        default = false;
        apply = value: if value then "true" else "false";
        description = "Whether to enable ${desc}.";
      };
  in {
    enable = mkEnableOption "hishtory";

    enableZshIntegration = mkEnableOption "hishtory's Zsh integration";
    enableFishIntegration = mkEnableOption "hishtory's Fish integration";
    enableBashIntegration = mkEnableOption "hishtory's Bash integration";

    enableConfig = mkEnableOption "configuration of hishtory via home-manager";

    settings = {
      custom-columns = mkOption {
        default = { };
        example = literalExpression ''
          {
            git_remote = "(git remote -v 2>/dev/null | grep origin 1>/dev/null ) && git remote get-url origin || true";
          }
        '';
        description = ''
          An attribute set that maps custom-columns (the top level attribute names in
          this option) to command strings or directly to build outputs.
        '';
        type = types.attrsOf types.str;
      };
      enable-control-r = trueFalseOption "Control+R integration for your shell";
      displayed-columns = mkOption {
        default =
          [ "Hostname" "CWD" "Timestamp" "Runtime" "Exit Code" "Command" ];
        example = literalExpression "[git_remote]";
        description = "A list of custom columns to display.";
        type = types.listOf types.str;
      };
      beta-mode = trueFalseOption "beta features";
      filter-duplicate-commands =
        trueFalseOption "filtering of duplicate commands";
      timestamp-format = mkOption {
        default = "Jan 2 2006 15:04:05 MST";
        example = "2006/Jan/2 15:04";
        description =
          "Custom timestamp format, should be in the format used by Go's time.Format(...).";
        type = types.str;
      };
    };

    package = mkPackageOption pkgs "hishtory" { };
  };
}
