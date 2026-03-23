{ config, lib, ... }:

let
  shellIntegrationParameters = {
    inherit config;
    baseName = "Shell";
  };
in
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

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption shellIntegrationParameters;
    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption shellIntegrationParameters;
    enableIonIntegration = lib.hm.shell.mkIonIntegrationOption shellIntegrationParameters;
    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption shellIntegrationParameters;
    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption shellIntegrationParameters;
  };
}
