{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;

  cfg = config.programs.keychain;

  shellCommand = "${cfg.package}/bin/keychain --eval ${lib.concatStringsSep " " cfg.extraFlags} ${lib.concatStringsSep " " cfg.keys}";

in
{
  meta.maintainers = [ ];

  imports = [
    (lib.mkRemovedOptionModule [
      "programs"
      "keychain"
      "agents"
    ] "Remove this option; keychain 2.9.0 no longer supports it.")
    (lib.mkRemovedOptionModule [
      "programs"
      "keychain"
      "inheritType"
    ] "Remove this option; keychain 2.9.0 no longer supports it.")
  ];

  options.programs.keychain = {
    enable = lib.mkEnableOption "keychain";

    package = lib.mkPackageOption pkgs "keychain" { };

    keys = mkOption {
      type = types.listOf types.str;
      default = [ "id_rsa" ];
      description = ''
        Keys to add to keychain.
      '';
    };

    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [ "--quiet" ];
      description = ''
        Extra flags to pass to keychain.
      '';
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    enableXsessionIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to run keychain from your {file}`~/.xsession`.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(SHELL=bash ${shellCommand})"
    '';
    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
      SHELL=fish eval (${shellCommand})
    '';
    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
      eval "$(SHELL=zsh ${shellCommand})"
    '';
    programs.nushell.extraConfig = mkIf cfg.enableNushellIntegration ''
      let keychain_shell_command = (SHELL=bash ${shellCommand}| parse -r '(\w+)="?(.*?)"?; export \1' | transpose -ird)
      if not ($keychain_shell_command|is-empty) {
        $keychain_shell_command | load-env
      }
    '';
    xsession.initExtra = mkIf cfg.enableXsessionIntegration ''
      eval "$(SHELL=bash ${shellCommand})"
    '';
  };
}
