{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  meta.maintainers = [ lib.hm.maintainers.ilaumjd ];

  options.programs.thefuck = {
    enable = lib.mkEnableOption "thefuck - magnificent app that corrects your previous console command";

    package = lib.mkPackageOption pkgs "thefuck" { };

    enableInstantMode = lib.mkEnableOption "thefuck's experimental instant mode";

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    alias = lib.mkOption {
      type = lib.types.str;
      default = "fuck";
      description = "Alias used to invoke `thefuck`.";
    };
  };

  config =
    let
      cfg = config.programs.thefuck;

      cliArgs = lib.cli.toGNUCommandLineShell { } {
        alias = cfg.alias;
        enable-experimental-instant-mode = cfg.enableInstantMode;
      };

      shEvalCmd = ''
        eval "$(${cfg.package}/bin/thefuck ${cliArgs})"
      '';
    in
    mkIf cfg.enable {
      home.packages = [ cfg.package ];

      programs.bash.initExtra = mkIf cfg.enableBashIntegration shEvalCmd;

      programs.fish.functions = mkIf cfg.enableFishIntegration {
        fuck = {
          description = "Correct your previous console command";
          body = ''
            set -l fucked_up_command $history[1]
            env TF_SHELL=fish TF_ALIAS=${cfg.alias} PYTHONIOENCODING=utf-8 ${cfg.package}/bin/thefuck $fucked_up_command THEFUCK_ARGUMENT_PLACEHOLDER $argv | read -l unfucked_command
            if [ "$unfucked_command" != "" ]
              eval $unfucked_command
              builtin history delete --exact --case-sensitive -- $fucked_up_command
              builtin history merge
            end
          '';
        };
      };

      programs.zsh.initContent = mkIf cfg.enableZshIntegration shEvalCmd;

      programs.nushell = mkIf cfg.enableNushellIntegration {
        extraConfig = ''
          alias ${cfg.alias} = ${cfg.package}/bin/thefuck $"(history | last 1 | get command | get 0)"
        '';
      };
    };
}
