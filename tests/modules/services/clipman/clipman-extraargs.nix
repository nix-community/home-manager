{
  home.stateVersion = "21.11";

  services.clipman = {
    enable = true;
    extraArgs = [
      "--max-items"
      "123"
    ];
  };

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/clipman.service)
    assertFileContent "$serviceFile" ${./clipman-extraargs.service}
  '';
}
