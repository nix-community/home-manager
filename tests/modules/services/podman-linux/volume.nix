{
  imports = [ ./podman-stubs.nix ];

  services.podman = {
    enable = true;
    volumes = {
      "my-vol" = {
        device = "tmpfs";
        extraConfig = { Volume = { User = 1000; }; };
        extraPodmanArgs = [ "--module=/etc/nvd.conf" ];
        group = 1000;
        type = "tmpfs";
      };

      "my-vol-2" = {
        extraConfig = { Volume = { VolumeName = "some-other-volume-name"; }; };
      };
    };
  };

  test.asserts.assertions.expected = [
    ''
      In 'my-vol-2' config. Volume.VolumeName: 'some-other-volume-name' does not match expected type: value "my-vol-2" (singular enum)''
  ];

  nmt.script = ''
    configPath=home-files/.config/systemd/user
    volumeFile=$configPath/podman-my-vol-volume.service
    assertFileExists $volumeFile

    volumeFile=$(normalizeStorePaths $volumeFile)

    assertFileContent $volumeFile ${./volume-expected.service}
  '';
}
