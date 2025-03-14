{ config, lib, pkgs, ... }:
with lib;
let cfg = config.programs.scmpuff;
in {
  meta.maintainers = [ maintainers.cpcloud ];

  options.programs.scmpuff = {
    enable = mkEnableOption ''
      scmpuff, a command line tool that allows you to work quicker with Git by
      substituting numeric shortcuts for files'';

    package = mkOption {
      type = types.package;
      default = pkgs.scmpuff;
      defaultText = literalExpression "pkgs.scmpuff";
      description = "Package providing the {command}`scmpuff` tool.";
    };

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };

    enableAliases = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable aliases (e.g. gs, ga, gd, gco).
      '';
    };
  };

  config = mkIf cfg.enable (let
    mkArgs = shell:
      concatStringsSep " " ([ "--shell=${shell}" ]
        ++ optional (!cfg.enableAliases) "--aliases=false");
  in {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(${cfg.package}/bin/scmpuff init ${mkArgs "bash"})"
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      eval "$(${cfg.package}/bin/scmpuff init ${mkArgs "zsh"})"
    '';

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration
      (mkAfter ''
        ${cfg.package}/bin/scmpuff init ${mkArgs "fish"} | source
      '');
  });
}
