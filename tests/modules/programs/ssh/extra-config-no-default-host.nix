{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    extraConfig = ''
      MyExtraOption no
      AnotherOption 3
    '';
  };

  test.asserts.assertions.expected = [
    ''Cannot set `programs.ssh.extraConfig` if `programs.ssh.matchBlocks."*"` (default host config) is not declared.''
  ];
}
