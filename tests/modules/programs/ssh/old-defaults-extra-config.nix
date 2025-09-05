{
  programs.ssh = {
    enable = true;
    extraConfig = ''
      MyExtraOption no
      AnotherOption 3
    '';
  };

  test.asserts.warnings.expected = [
    ''
      `programs.ssh` default values will be removed in the future.
      Consider setting `programs.ssh.enableDefaultConfig` to false,
      and manually set the default values you want to keep at
      `programs.ssh.matchBlocks."*"`.
    ''
  ];

  nmt.script = ''
    assertFileExists home-files/.ssh/config
    assertFileContent home-files/.ssh/config \
    ${./old-defaults-extra-config-expected.conf}
  '';
}
