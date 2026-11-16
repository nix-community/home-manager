{
  programs.nh = {
    enable = true;

    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = [
        "--keep"
        "5"
        "--keep-since"
        "3d"
      ];
    };
  };

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/nh-clean.service)

    assertFileContent "$serviceFile" ${./clean-extra-args.service}
  '';
}
