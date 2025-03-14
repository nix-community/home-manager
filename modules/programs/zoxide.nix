{ config, lib, pkgs, ... }:
let
  cfg = config.programs.zoxide;

  cfgOptions = lib.concatStringsSep " " cfg.options;
in {
  meta.maintainers = [ ];

  options.programs.zoxide = {
    enable = lib.mkEnableOption "zoxide";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.zoxide;
      defaultText = lib.literalExpression "pkgs.zoxide";
      description = ''
        Zoxide package to install.
      '';
    };

    options = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--no-cmd" ];
      description = ''
        List of options to pass to zoxide init.
      '';
    };

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration =
      lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = lib.mkIf cfg.enableBashIntegration
      (lib.mkOrder 2000 ''
        eval "$(${cfg.package}/bin/zoxide init bash ${cfgOptions})"
      '');

    programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration
      (lib.mkOrder 2000 ''
        eval "$(${cfg.package}/bin/zoxide init zsh ${cfgOptions})"
      '');

    programs.fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration ''
      ${cfg.package}/bin/zoxide init fish ${cfgOptions} | source
    '';

    programs.nushell = lib.mkIf cfg.enableNushellIntegration {
      extraEnv = ''
        let zoxide_cache = "${config.xdg.cacheHome}/zoxide"
        if not ($zoxide_cache | path exists) {
          mkdir $zoxide_cache
        }
        ${cfg.package}/bin/zoxide init nushell ${cfgOptions} |
          save --force ${config.xdg.cacheHome}/zoxide/init.nu
      '';
      extraConfig = ''
        source ${config.xdg.cacheHome}/zoxide/init.nu
      '';
    };
  };
}
