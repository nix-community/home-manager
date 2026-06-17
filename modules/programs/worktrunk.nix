{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.worktrunk;
in
{
  meta.maintainers = with lib.hm.maintainers; [ conao3 ];

  options.programs.worktrunk = {
    enable = lib.mkEnableOption "worktrunk, a git worktree manager for parallel AI agent workflows";

    package = lib.mkPackageOption pkgs "worktrunk" { };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = lib.mkIf cfg.enableBashIntegration ''
      eval "$(${lib.getExe cfg.package} config shell init bash)"
    '';

    programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration (
      lib.mkOrder 851 ''
        eval "$(${lib.getExe cfg.package} config shell init zsh)"
      ''
    );

    programs.fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration ''
      ${lib.getExe cfg.package} config shell init fish | source
    '';

    programs.nushell = lib.mkIf cfg.enableNushellIntegration {
      extraConfig = ''
        source ${
          pkgs.runCommand "worktrunk-nushell-config.nu" { } ''
            ${lib.getExe cfg.package} config shell init nu >> "$out"
          ''
        }
      '';
    };
  };
}
