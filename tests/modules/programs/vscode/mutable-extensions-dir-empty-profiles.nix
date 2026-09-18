package:

_:

{
  # mutableExtensionsDir may be true when non-default profiles exist, as long
  # as none of them declare extensions.
  programs.vscode = {
    enable = true;
    inherit package;
    mutableExtensionsDir = true;
    profiles = {
      default = { };
      work = { };
    };
  };

  test.asserts.assertions.expected = [ ];

  nmt.script = ''
    assertPathNotExists "home-files/.vscode/profiles/work/extensions.json"
  '';
}
