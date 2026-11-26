{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.tere;

  # Shell integrations as suggested by tere (links pinned to a commit):
  # https://github.com/mgunyho/tere/blob/1538eb7c2dc7ee988d1f95741399f989fedc85ee/src/first_run_check.rs#L12-L20 (first-run message, Bash/Zsh;
  # the snippet itself comes from https://github.com/mgunyho/tere/blob/1538eb7c2dc7ee988d1f95741399f989fedc85ee/README.md#L49-L54)
  bashIntegration = ''
    tere() {
        local result=$(command tere "$@")
        [ -n "$result" ] && cd -- "$result"
    }
  '';

  # https://github.com/mgunyho/tere/blob/1538eb7c2dc7ee988d1f95741399f989fedc85ee/README.md#L62-L66 (fish)
  fishIntegration = ''
    set --local result (command tere $argv)
    [ -n "$result" ] && cd -- "$result"
  '';

  # https://github.com/mgunyho/tere/blob/1538eb7c2dc7ee988d1f95741399f989fedc85ee/README.md#L90-L96 (Nushell)
  nushellIntegration = ''
    def --wrapped --env tere [...args] {
        let result = ( ^tere ...$args )
        if $result != "" {
            cd $result
        }
    }
  '';
in
{
  meta.maintainers = [ lib.maintainers.NicoWeio ];

  options.programs.tere = {
    enable = lib.mkEnableOption "tere, a terminal file explorer";

    package = lib.mkPackageOption pkgs "tere" { nullable = true; };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    programs.bash.initExtra = lib.mkIf cfg.enableBashIntegration bashIntegration;

    programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration bashIntegration;

    programs.fish.functions.tere = lib.mkIf cfg.enableFishIntegration fishIntegration;

    programs.nushell.extraConfig = lib.mkIf cfg.enableNushellIntegration nushellIntegration;
  };
}
