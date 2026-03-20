{
  targets.genericLinux.gpu.enable = true;

  nmt.script = ''
    assertFileExists home-path/bin/non-nixos-gpu-setup
    assertFileContains activate "checkExistingGpuDrivers"
  '';
}
