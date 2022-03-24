{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.just;

in {
  meta.maintainers = [ hm.maintainers.maximsmol ];

  options.programs.just = {
    enable = mkEnableOption
      "just, a handy way to save and run project-specific commands";

    package = mkOption {
      type = types.package;
      default = pkgs.just;
      defaultText = literalExpression "pkgs.just";
      description = "Package providing the <command>just</command> tool.";
    };

    enableBashIntegration = mkEnableOption "Bash integration" // {
      default = true;
    };

    enableZshIntegration = mkEnableOption "Zsh integration" // {
      default = true;
    };

    enableFishIntegration = mkEnableOption "Fish integration" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      source ${cfg.package}/share/bash-completion/completions/just.bash
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      source ${cfg.package}/share/zsh/site-functions/_just
    '';

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      source ${cfg.package}/share/fish/vendor_completions.d/just.fish
    '';

  };
}
