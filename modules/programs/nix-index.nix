{ config, lib, pkgs, ... }:
let cfg = config.programs.nix-index;
in {
  meta.maintainers = with lib.hm.maintainers; [ ambroisie ];

  options.programs.nix-index = with lib; {
    enable = mkEnableOption "nix-index, a file database for nixpkgs";

    package = mkOption {
      type = types.package;
      default = pkgs.nix-index;
      defaultText = literalExpression "pkgs.nix-index";
      description = "Package providing the <command>nix-index</command> tool.";
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

  config = lib.mkIf cfg.enable {
    assertions = let
      checkOpt = name: {
        assertion = cfg.${name} -> !config.programs.command-not-found.enable;
        message = ''
          The 'programs.command-not-found.enable' option is mutually exclusive
          with the 'programs.nix-index.${name}' option.
        '';
      };
    in [ (checkOpt "enableBashIntegration") (checkOpt "enableZshIntegration") ];

    home.packages = [ cfg.package ];

    programs.bash.initExtra = lib.mkIf cfg.enableBashIntegration ''
      source ${cfg.package}/etc/profile.d/command-not-found.sh
    '';

    programs.zsh.initExtra = lib.mkIf cfg.enableZshIntegration ''
      source ${cfg.package}/etc/profile.d/command-not-found.sh
    '';

    # See https://github.com/bennofs/nix-index/issues/126
    programs.fish.shellInit = let
      wrapper = pkgs.writeScript "command-not-found" ''
        #!${pkgs.bash}/bin/bash
        source ${cfg.package}/etc/profile.d/command-not-found.sh
        command_not_found_handle "$@"
      '';
    in lib.mkIf cfg.enableFishIntegration ''
      function __fish_command_not_found_handler --on-event fish_command_not_found
          ${wrapper} $argv
      end
    '';
  };
}
