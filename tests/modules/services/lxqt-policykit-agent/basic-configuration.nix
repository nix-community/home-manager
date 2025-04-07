{
  services.lxqt-policykit-agent.enable = true;

  nmt.script = ''
    clientServiceFile=home-files/.config/systemd/user/lxqt-policykit-agent.service

    assertFileExists $clientServiceFile
    assertFileContent $clientServiceFile ${builtins.toFile "expected.service" ''
      [Install]
      WantedBy=graphical-session.target

      [Service]
      ExecStart=@lxqt-policykit@/bin/lxqt-policykit-agent

      [Unit]
      After=graphical-session-pre.target
      Description=LXQT PolicyKit Agent
      PartOf=graphical-session.target
    ''}
  '';
}
