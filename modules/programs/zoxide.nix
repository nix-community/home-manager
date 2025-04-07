{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.zoxide;

  cfgOptions = lib.concatStringsSep " " cfg.options;
in
{
  meta.maintainers = [ ];

  options.programs.zoxide = {
    enable = lib.mkEnableOption "zoxide";

    package = lib.mkPackageOption pkgs "zoxide" { };

    options = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--no-cmd" ];
      description = ''
        List of options to pass to zoxide init.
      '';
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = lib.mkIf cfg.enableBashIntegration (
      lib.mkOrder 2000 ''
        eval "$(${lib.getExe cfg.package} init bash ${cfgOptions})"
      ''
    );

    programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration (
      lib.mkOrder 2000 ''
        eval "$(${lib.getExe cfg.package} init zsh ${cfgOptions})"
      ''
    );

    programs.fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration ''
      ${lib.getExe cfg.package} init fish ${cfgOptions} | source
    '';

    programs.nushell = lib.mkIf cfg.enableNushellIntegration {
      extraConfig = ''
        source ${
          pkgs.runCommand "zoxide-nushell-config.nu" { } ''
            ${lib.getExe cfg.package} init nushell ${cfgOptions} >> "$out"
          ''
        }
      '';
    };
  };
}
