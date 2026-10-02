package:

{ pkgs, ... }:

let
  fakeExtension =
    pkgs.runCommand "fake-extension" { } ''
      mkdir -p $out/share/vscode/extensions/fake.extension
      touch $out/share/vscode/extensions/fake.extension/package.json
    ''
    // {
      vscodeExtUniqueId = "fake.extension";
      vscodeExtPublisher = "fake";
      version = "1.0.0";
    };
in

{
  # Regression test: mutableExtensionsDir defaults to true when there are no
  # non-default profiles, and must remain usable when the default profile
  # declares extensions.
  programs.vscode = {
    enable = true;
    inherit package;
    profiles.default.extensions = [ fakeExtension ];
  };

  test.asserts.assertions.expected = [ ];

  nmt.script = ''
    assertFileExists "home-files/.vscode/extensions/fake.extension/package.json"
  '';
}
