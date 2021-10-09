{ ... }:

{
  programs.rofi = {
    enable = true;
    colors = { };
  };

  test.stubs.rofi = { };
  test.asserts.assertions.expected = [
    (let offendingFile = toString ./config-with-deprecated-options.nix;
    in ''
      The option definition `programs.rofi.colors' in `${offendingFile}' no longer has any effect; please remove it.
      Please use a Rofi theme instead.
    '')
  ];
}
