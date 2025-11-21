{ config, lib, ... }:

{
  options.home.shell = {
    enableShellIntegration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = ''
        Whether to globally enable shell integration for all supported shells.

        Individual shell integrations can be overridden with their respective
        `shell.enable<SHELL>Integration` option. For example, the following
        declaration globally disables shell integration for Bash:

        ```nix
        home.shell.enableBashIntegration = false;
        ```
      '';
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption {
      inherit config;
      baseName = "Shell";
    };
    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption {
      inherit config;
      baseName = "Shell";
    };
    enableIonIntegration = lib.hm.shell.mkIonIntegrationOption {
      inherit config;
      baseName = "Shell";
    };
    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption {
      inherit config;
      baseName = "Shell";
    };
    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption {
      inherit config;
      baseName = "Shell";
    };
  };
}
