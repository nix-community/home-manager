{ config, ... }:

{
  nix.package = config.lib.test.mkStubPackage { name = "my-test-nix"; };

  services.home-manager.autoUpgrade = {
    enable = true;
    frequency = "daily";
  };

  nmt.script = ''
    serviceFile="home-files/.config/systemd/user/home-manager-auto-upgrade.service"
    assertFileExists "$serviceFile"

    scriptPath=$(grep -oP 'ExecStart=\K.+' "$TESTED/$serviceFile")
    assertFileRegex "$scriptPath" "my-test-nix"
  '';
}
