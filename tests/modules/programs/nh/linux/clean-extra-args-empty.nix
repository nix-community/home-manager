{
  programs.nh = {
    enable = true;

    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = [ ];
    };
  };

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/nh-clean.service)

    assertFileContent "$serviceFile" ${./clean-extra-args-empty.service}
  '';
}
