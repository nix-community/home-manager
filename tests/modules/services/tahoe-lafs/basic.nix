{
  services.tahoe-lafs.enable = true;

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/tahoe-lafs.service

    assertFileContent "$serviceFile" ${builtins.toFile "tahoe-lafs.service" ''
      [Install]
      WantedBy=default.target

      [Service]
      ExecStart=@tahoe-lafs@/bin/tahoe run -C %h/.tahoe

      [Unit]
      Description=Tahoe-LAFS
    ''}
    assertFileExists home-files/.config/systemd/user/default.target.wants/tahoe-lafs.service
  '';
}
