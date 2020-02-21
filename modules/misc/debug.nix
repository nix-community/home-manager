{ config, pkgs, lib, ... }:

with lib;

{
  options.home = {
    enableDebugInfo = mkEnableOption "" // {
      description = ''
        Some Nix-packages provide debug symbols for
        <command>gdb</command> in the <literal>debug</literal>-output.
        This option ensures that those are automatically fetched from
        the binary cache if available and <command>gdb</command> is
        configured to find those symbols.
      '';
    };
  };

  config = mkIf config.home.enableDebugInfo {
    home.extraOutputsToInstall = [ "debug" ];

    home.sessionVariables = {
      NIX_DEBUG_INFO_DIRS =
        "$NIX_DEBUG_INFO_DIRS\${NIX_DEBUG_INFO_DIRS:+:}${config.home.profileDirectory}/lib/debug";
    };
  };
}
