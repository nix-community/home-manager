{ config, lib, pkgs, ... }:

with lib;

{
  meta.maintainers = [ hm.maintainers.ilaumjd ];

  options.programs.asdf-vm = {
    enable = mkEnableOption "asdf-vm - asdf runtime version manager";

    package = mkPackageOption pkgs "asdf-vm" { };

    enableBashIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Bash integration.
      '';
    };

    enableFishIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Fish integration.
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

  config = let cfg = config.programs.asdf-vm;
  in mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      . "${cfg.package}/share/asdf-vm/asdf.sh"
      . "${cfg.package}/share/asdf-vm/completions/asdf.bash"
    '';

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
      source "${cfg.package}/share/asdf-vm/asdf.fish"
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      . "${cfg.package}/share/asdf-vm/asdf.sh"
    '';

  };
}
