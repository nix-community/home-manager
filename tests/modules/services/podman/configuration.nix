{ pkgs, ... }:
{
  services.podman = {
    enable = true;
    settings = {
      containers = {
        network = {
          default_subnet = "172.16.10.0/24";
          default_subnet_pools = [
            {
              base = "172.16.11.0/24";
              size = 24;
            }
            {
              base = "172.16.12.0/24";
              size = 24;
            }
          ];
        };
      };
      storage = {
        storage = {
          runroot = "$HOME/.containers/runroot";
          graphroot = "$HOME/.containers/graphroot";
        };
      };
      registries = {
        search = [ "docker.io" ];
        block = [
          "ghcr.io"
          "gallery.ecr.aws"
        ];
        insecure = [ "quay.io" ];
        registry = [
          {
            location = "quay.io";
            blocked = true;
          }
          {
            location = "gallery.ecr.aws";
            blocked = false;
          }
          {
            location = "registry.fedoraproject.org";
            insecure = true;
          }
        ];
      };
      policy = {
        default = [ { type = "insecureAcceptAnything"; } ];
      };
      mounts = [ "/usr/share/secrets:/run/secrets" ];
    };
  };

  test.asserts.warnings.expected = [
    ''
      `services.podman.settings.registries.insecure` and
      `services.podman.settings.registries.block` are deprecated and will be
      removed in a future release.

      Use `services.podman.settings.registries.registry` entries with
      `location`, `insecure`, and `blocked` instead.
    ''
  ];

  nmt.script =
    if pkgs.stdenv.hostPlatform.isDarwin then
      ''
        # On Darwin, container config files are not part of the home-files
        # generation — they're installed into ~/.config/containers by an
        # activation script so they can be bind-mounted into the podman VM.
        assertFileExists activate
        assertFileRegex activate 'podmanContainersConfig'
        assertFileRegex activate 'install -m 0644'
        assertFileRegex activate 'policy\.json'
        assertFileRegex activate 'registries\.conf'
        assertFileRegex activate 'storage\.conf'
        assertFileRegex activate 'containers\.conf'
        assertFileRegex activate 'mounts\.conf'

        # Verify that config directory is automatically mounted into podman
        # machines at the canonical /var/home path
        assertFileRegex activate '\$HOME/\.config/containers:/var/home/core/\.config/containers'
      ''
    else
      ''
        configPath=home-files/.config/containers
        containersFile=$configPath/containers.conf
        policyFile=$configPath/policy.json
        registriesFile=$configPath/registries.conf
        storageFile=$configPath/storage.conf
        mountsFile=$configPath/mounts.conf

        assertFileExists $containersFile
        assertFileExists $policyFile
        assertFileExists $registriesFile
        assertFileExists $storageFile
        assertFileExists $mountsFile

        containersFile=$(normalizeStorePaths $containersFile)
        policyFile=$(normalizeStorePaths $policyFile)
        registriesFile=$(normalizeStorePaths $registriesFile)
        storageFile=$(normalizeStorePaths $storageFile)
        mountsFile=$(normalizeStorePaths $mountsFile)

        assertFileContent $containersFile ${./configuration-containers-expected.conf}
        assertFileContent $policyFile ${./configuration-policy-expected.json}
        assertFileContent $registriesFile ${./configuration-registries-expected.conf}
        assertFileContent $storageFile ${./configuration-storage-expected.conf}
        assertFileContent $mountsFile ${./configuration-mounts-expected.conf}
      '';
}
