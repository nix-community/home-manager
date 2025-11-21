{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.programs.pls;

  aliases = {
    ls = "${cfg.package}/bin/pls";
    ll = "${cfg.package}/bin/pls -d perm -d user -d group -d size -d mtime -d git";
  };
in
{
  imports =
    let
      msg = ''
        'programs.pls.enableAliases' has been deprecated and replaced with integration
        options per shell, for example, 'programs.pls.enableBashIntegration'.

        Note, the default for these options is 'true' so if you want to enable the
        aliases you can simply remove 'programs.pls.enableAliases' from your
        configuration.'';
    in
    [ (lib.mkRemovedOptionModule [ "programs" "pls" "enableAliases" ] msg) ];

  meta.maintainers = [ lib.maintainers.arjan-s ];

  options.programs.pls = {
    enable = lib.mkEnableOption "pls, a modern replacement for {command}`ls`";

    package = lib.mkPackageOption pkgs "pls" { };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.shellAliases = mkIf cfg.enableBashIntegration aliases;

    programs.fish = lib.mkMerge [
      (mkIf (!config.programs.fish.preferAbbrs) {
        shellAliases = mkIf cfg.enableFishIntegration aliases;
      })

      (mkIf config.programs.fish.preferAbbrs {
        shellAbbrs = mkIf cfg.enableFishIntegration aliases;
      })
    ];

    programs.zsh.shellAliases = mkIf cfg.enableZshIntegration aliases;
  };
}
