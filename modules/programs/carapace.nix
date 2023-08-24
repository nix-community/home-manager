{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkPackageOption mkIf;
  cfg = config.programs.carapace;
  bin = cfg.package + "/bin/carapace";
in {
  meta.maintainers = with lib.maintainers; [ weathercold ];

  options.programs.carapace = {
    enable =
      mkEnableOption "carapace, a multi-shell multi-command argument completer";
    package = mkPackageOption pkgs "carapace" { };
    enableBashIntegration = mkEnableOption "Bash integration" // {
      default = true;
    };
    enableZshIntegration = mkEnableOption "Zsh integration" // {
      default = true;
    };
    enableFishIntegration = mkEnableOption "Fish integration" // {
      default = true;
    };
    enableNushellIntegration = mkEnableOption "Nushell integration" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs = {
      bash.initExtra = mkIf cfg.enableBashIntegration ''
        source <(${bin} _carapace bash)
      '';

      zsh.initExtra = mkIf cfg.enableZshIntegration ''
        source <(${bin} _carapace zsh)
      '';

      fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
        mkdir -p ${config.xdg.configHome}/fish/completions
        # Disable auto-loaded completions (https://github.com/rsteube/carapace-bin/issues/185)
        ${bin} --list | awk '{print $1}' | xargs -I{} touch ${config.xdg.configHome}/fish/completions/{}.fish
        ${bin} _carapace fish | source
      '';

      nushell = mkIf cfg.enableNushellIntegration {
        extraEnv = ''
          let carapace_cache = "${config.xdg.cacheHome}/carapace"
          if not ($carapace_cache | path exists) {
            mkdir $carapace_cache
          }
          ${bin} _carapace nushell | save -f $"($carapace_cache)/init.nu"
        '';
        extraConfig = ''
          source ${config.xdg.cacheHome}/carapace/init.nu
        '';
      };
    };
  };
}
