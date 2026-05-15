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
      renamedOptions = {
        forwardAgent = "ForwardAgent";
        addKeysToAgent = "AddKeysToAgent";
        compression = "Compression";
        serverAliveInterval = "ServerAliveInterval";
        serverAliveCountMax = "ServerAliveCountMax";
        hashKnownHosts = "HashKnownHosts";
        userKnownHostsFile = "UserKnownHostsFile";
        controlMaster = "ControlMaster";
        controlPath = "ControlPath";
        controlPersist = "ControlPersist";
      };
      renamedOptionOrder = [
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
      old:
      let
        new = renamedOptions.${old};
      in
      "The option `programs.ssh.${old}' defined in ${
        lib.showFiles options.programs.ssh.${old}.files
      } has been renamed to `programs.ssh.settings.*.${new}'."
    ) renamedOptionOrder;

  nmt.script = ''
    assertFileExists home-files/.ssh/config
    assertFileContent home-files/.ssh/config \
    ${./renamed-options-expected.conf}
  '';
}
