{
  config,
  lib,
  pkgs,
  ...
}:

{
  nix = {
    package = config.lib.test.mkStubPackage {
      version = lib.getVersion pkgs.nixVersions.stable;
    };

    distributedBuilds = true;

    buildMachines = [
      {
        hostName = "foo.example.com";
        sshUser = "bob";
        sshKey = "/path/to/ssh-key";
        publicHostKey = "PUBLIC_HOST_KEY";
        systems = [ "aarch64-linux" ];
        speedFactor = 4;
        protocol = "ssh-ng";
        maxJobs = 2;
        supportedFeatures = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
        mandatoryFeatures = [
          "big-parallel"
        ];
      }
      {
        hostName = "192.168.1.42";
        sshUser = "alice";
        sshKey = "~/.ssh/id_rsa";
        publicHostKey = "PUBLIC_HOST_KEY_2";
        systems = [
          "aarch64-darwin"
          "x86_64-darwin"
        ];
        supportedFeatures = [
          "apple-virt"
          "big-parallel"
          "nixos-test"
        ];
      }
    ];
  };

  nmt.script = ''
    assertFileExists "home-files/.config/nix/machines"

    assertFileContent \
      home-files/.config/nix/machines \
      ${./example-settings-expected}

    assertFileContains home-files/.config/nix/nix.conf \
      'builders = @${config.xdg.configHome}/nix/machines'
  '';
}
