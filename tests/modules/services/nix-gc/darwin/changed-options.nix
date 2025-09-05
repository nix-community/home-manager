{ lib, options, ... }:

{
  nix.gc = {
    automatic = true;
    frequency = "monthly";
    options = "--delete-older-than 30d";
  };

  test.asserts.warnings.expected = [
    "The option `nix.gc.frequency' defined in ${lib.showFiles options.nix.gc.frequency.files} has been changed to `nix.gc.dates' that has a different type. Please read `nix.gc.dates' documentation and update your configuration accordingly."
  ];

  nmt.script = ''
    serviceFile=LaunchAgents/org.nix-community.home.nix-gc.plist

    assertFileExists "$serviceFile"

    assertFileContent "$serviceFile" ${./expected-agent.plist}
  '';
}
