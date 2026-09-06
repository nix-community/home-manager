{
  programs.nh = {
    enable = true;

    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since=1 day";
    };
  };

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/nh-clean.service)

    assertFileContent "$serviceFile" ${./clean-extra-args-string.service}
  '';
}
