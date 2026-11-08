_: {
  programs.karabiner-elements = {
    enable = true;
  };

  test.asserts.assertions.expected = [
    ''
      The module programs.karabiner-elements does not support your platform. It only supports

        - aarch64-darwin''
  ];
}
