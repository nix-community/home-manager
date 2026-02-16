{
  config,
  lib,
  pkgs,
  ...
}:

let
  mockNvidiaDriver = config.lib.test.mkStubPackage {
    buildScript = ''
      mkdir -p $out/lib
      echo "MOCK_NVIDIA_DRIVER_FOR_TESTING" > $out/lib/nvidia-test-marker
    '';
  };

  # Override the package set to provide our mock driver. This also tests that a
  # custom package set can be used with this module. The mock driver needs to
  # support .override because the module calls it.
  customPkgs = pkgs // {
    linuxPackages = pkgs.linuxPackages // {
      nvidiaPackages = pkgs.linuxPackages.nvidiaPackages // {
        mkDriver = args: lib.makeOverridable (_: mockNvidiaDriver) { };
      };
    };
  };
in
{
  targets.genericLinux.gpu = {
    enable = true;
    packages = customPkgs;
    nvidia = {
      enable = true;
      version = "550.163.01";
      sha256 = "sha256-hfK1D5EiYcGRegss9+H5dDr/0Aj9wPIJ9NVWP3dNUC0=";
    };
  };

  nmt.script = ''
    setupScript="$TESTED/home-path/bin/non-nixos-gpu-setup"
    assertFileExists "$setupScript"

    # Find the service file
    storePath="$(dirname "$(readlink "''${setupScript}")")"/../
    servicePath="$storePath/lib/systemd/system/non-nixos-gpu.service"

    # Extract the GPU environment path
    envPath=$(grep -oP '/nix/store/[^/]+-non-nixos-gpu' "$servicePath" | head -1)

    if [[ -z "$envPath" ]]; then
      fail "Could not find GPU environment path in service file"
    fi

    markerFile="$envPath/lib/nvidia-test-marker"
    assertFileExists "$markerFile"
    assertFileContains "$markerFile" "MOCK_NVIDIA_DRIVER_FOR_TESTING"
  '';
}
