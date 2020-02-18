{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.lsd;

  aliases = {
    ls = "${pkgs.lsd}/bin/lsd";
    ll = "ls -l";
    la = "ls -a";
    lt = "ls --tree";
    lla = "ls -la";
  };

in {
  meta.maintainers = [ maintainers.marsam ];

  options.programs.lsd = {
    enable = mkEnableOption "lsd";

    enableAliases = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Whether to enable recommended lsd aliases.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.lsd ];

    programs.bash.shellAliases = mkIf cfg.enableAliases aliases;

    programs.zsh.shellAliases = mkIf cfg.enableAliases aliases;

    programs.fish.shellAliases = mkIf cfg.enableAliases aliases;
  };
}
