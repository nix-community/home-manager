{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.pls;

  aliases = {
    ls = "${cfg.package}/bin/pls";
    ll =
      "${cfg.package}/bin/pls -d perm -d user -d group -d size -d mtime -d git";
  };

in {
  meta.maintainers = [ maintainers.arjan-s ];

  options.programs.pls = {
    enable = mkEnableOption "pls, a modern replacement for {command}`ls`";

    package = mkPackageOption pkgs "pls" { };

    enableAliases = mkEnableOption "recommended pls aliases";
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.shellAliases = mkIf cfg.enableAliases aliases;

    programs.fish = mkMerge [
      (mkIf (!config.programs.fish.preferAbbrs) {
        shellAliases = mkIf cfg.enableAliases aliases;
      })

      (mkIf config.programs.fish.preferAbbrs {
        shellAbbrs = mkIf cfg.enableAliases aliases;
      })
    ];

    programs.zsh.shellAliases = mkIf cfg.enableAliases aliases;
  };
}
