{
  services.poweralertd = {
    enable = true;
    extraArgs = [
      "-s"
      "-S"
    ];
  };

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/poweralertd.service)
    assertFileContent "$serviceFile" ${./poweralertd.service}
  '';
}
