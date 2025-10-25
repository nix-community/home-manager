{ config, lib, ... }:

{
  targets.genericLinux.gpu = {
    enable = true;
  };

  nmt.script = ''
    setupScript="$TESTED/home-path/bin/non-nixos-gpu-setup"
    assertFileExists "$setupScript"
    assertFileIsExecutable "$setupScript"

    # Check that no placeholders remain
    assertFileNotRegex "$setupScript" '@@[^@]+@@'

    # Find and check the resources directory
    resourcesPath=$(grep -oP '/nix/store/[^/]+-non-nixos-gpu/resources' "$setupScript" | head -1)
    assertDirectoryExists "$resourcesPath"

    serviceFile="$resourcesPath/non-nixos-gpu.service"
    assertFileExists "$serviceFile"

    # Check that no placeholders remain
    assertFileNotRegex "$serviceFile" '@@[^@]\+@@'
    assertFileNotRegex "$setupScript" '@@[^@]\+@@'
  '';
}
