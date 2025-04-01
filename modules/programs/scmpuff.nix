{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf;

  cfg = config.programs.scmpuff;
in {
  meta.maintainers = [ lib.maintainers.cpcloud ];

  options.programs.scmpuff = {
    enable = lib.mkEnableOption ''
      scmpuff, a command line tool that allows you to work quicker with Git by
      substituting numeric shortcuts for files'';

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.scmpuff;
      defaultText = lib.literalExpression "pkgs.scmpuff";
      description = "Package providing the {command}`scmpuff` tool.";
    };

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };

    enableAliases = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = ''
        Whether to enable aliases (e.g. gs, ga, gd, gco).
      '';
    };
  };

  config = mkIf cfg.enable (let
    mkArgs = shell:
      lib.concatStringsSep " " ([ "--shell=${shell}" ]
        ++ lib.optional (!cfg.enableAliases) "--aliases=false");
  in {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(${cfg.package}/bin/scmpuff init ${mkArgs "bash"})"
    '';

    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
      eval "$(${cfg.package}/bin/scmpuff init ${mkArgs "zsh"})"
    '';

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration
      (lib.mkAfter ''
        ${cfg.package}/bin/scmpuff init ${mkArgs "fish"} | source
      '');
  });
}
