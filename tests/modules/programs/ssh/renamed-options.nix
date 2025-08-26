{ lib, options, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    forwardAgent = true;
    addKeysToAgent = "yes";
    compression = true;
    serverAliveInterval = 1;
    serverAliveCountMax = 2;
    hashKnownHosts = true;
    userKnownHostsFile = "~/.ssh/my_known_hosts";
    controlMaster = "yes";
    controlPath = "~/.ssh/myfile-%r@%n:%p";
    controlPersist = "10m";
  };

  test.asserts.warnings.expected =
    let
      renamedOptions = [
        "controlPersist"
        "controlPath"
        "controlMaster"
        "userKnownHostsFile"
        "hashKnownHosts"
        "serverAliveCountMax"
        "serverAliveInterval"
        "compression"
        "addKeysToAgent"
        "forwardAgent"
      ];
    in
    map (
      o:
      "The option `programs.ssh.${o}' defined in ${
        lib.showFiles options.programs.ssh.${o}.files
      } has been renamed to `programs.ssh.matchBlocks.*.${o}'."
    ) renamedOptions;

  nmt.script = ''
    assertFileExists home-files/.ssh/config
    assertFileContent home-files/.ssh/config \
    ${./renamed-options-expected.conf}
  '';
}
