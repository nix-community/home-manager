{ config, lib, ... }:

{
  options.home = {
    enableDebugInfo = lib.mkEnableOption "" // {
      description = ''
        Some Nix packages provide debug symbols for
        {command}`gdb` in the `debug` output.
        This option ensures that those are automatically fetched from
        the binary cache if available and {command}`gdb` is
        configured to find those symbols.
      '';
    };
  };

  config = lib.mkIf config.home.enableDebugInfo {
    home.extraOutputsToInstall = [ "debug" ];

    home.sessionSearchVariables = {
      NIX_DEBUG_INFO_DIRS =
        "$NIX_DEBUG_INFO_DIRS\${NIX_DEBUG_INFO_DIRS:+:}${config.home.profileDirectory}/lib/debug";
    };
  };
}
