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
        block = [ "ghcr.io" "gallery.ecr.aws" ];
        insecure = [ "quay.io" ];
        search = [ "docker.io" ];
      };
      policy = { default = [{ type = "insecureAcceptAnything"; }]; };
    };
  };

  nmt.script = ''
    configPath=home-files/.config/containers
    containersFile=$configPath/containers.conf
    policyFile=$configPath/policy.json
    registriesFile=$configPath/registries.conf
    storageFile=$configPath/storage.conf

    assertFileExists $containersFile
    assertFileExists $policyFile
    assertFileExists $registriesFile
    assertFileExists $storageFile

    containersFile=$(normalizeStorePaths $containersFile)
    policyFile=$(normalizeStorePaths $policyFile)
    registriesFile=$(normalizeStorePaths $registriesFile)
    storageFile=$(normalizeStorePaths $storageFile)

    assertFileContent $containersFile ${
      ./configuration-containers-expected.conf
    }
    assertFileContent $policyFile ${./configuration-policy-expected.json}
    assertFileContent $registriesFile ${
      ./configuration-registries-expected.conf
    }
    assertFileContent $storageFile ${./configuration-storage-expected.conf}
  '';
}
