{
  programs.sbt = {
    enable = true;
    baseConfigPath = "gone";
  };

  test.asserts.assertions.expected = [
    (let offendingFile = toString ./deprecated-options.nix;
    in ''
      The option definition `programs.sbt.baseConfigPath' in `${offendingFile}' no longer has any effect; please remove it.
      Use programs.sbt.baseUserConfigPath instead, but note that the semantics are slightly different.
    '')
  ];
}
