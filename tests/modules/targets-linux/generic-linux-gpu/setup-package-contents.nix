{ config, lib, ... }:

{
  targets.genericLinux.gpu = {
    enable = true;
    nixStateDirectory = "/custom/state/directory";
  };

  nmt.script = ''
    setupScript="$TESTED/home-path/bin/non-nixos-gpu-setup"
    assertFileExists "$setupScript"
    assertFileIsExecutable "$setupScript"

    # Find and check the resources directory
    resourcesPath=$(grep -oP '/nix/store/[^/]+-non-nixos-gpu/resources' "$setupScript" | head -1)
    assertDirectoryExists "$resourcesPath"

    # Check that gcroots dir was set
    cat "$setupScript"
    assertFileRegex "$setupScript" ' "/custom/state/directory"/gcroots'

    serviceFile="$resourcesPath/non-nixos-gpu.service"
    assertFileExists "$serviceFile"

    # Check that no placeholders remain
    assertFileNotRegex "$serviceFile" '@@[^@]\+@@'
    assertFileNotRegex "$setupScript" '@@[^@]\+@@'
  '';
}
