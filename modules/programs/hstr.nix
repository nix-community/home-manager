{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.hstr;

in {
  meta.maintainers = [ hm.maintainers.Dines97 ];

  options.programs.hstr = {
    enable = mkEnableOption ''
      Bash And Zsh shell history suggest box - easily view, navigate, search and
      manage your command history'';

    package = mkPackageOption pkgs "hstr" { };

    enableBashIntegration = mkEnableOption "Bash integration" // {
      default = true;
    };

    enableZshIntegration = mkEnableOption "Zsh integration" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(${cfg.package}/bin/hstr --show-configuration)"
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      eval "$(${cfg.package}/bin/hstr --show-zsh-configuration)"
    '';
  };
}
