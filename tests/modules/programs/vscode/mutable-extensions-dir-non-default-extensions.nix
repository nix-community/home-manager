package:

{ pkgs, ... }:

let
  fakeExtension = pkgs.runCommand "fake-extension" { } ''
    mkdir -p $out/share/vscode/extensions/fake.extension
    touch $out/share/vscode/extensions/fake.extension/package.json
  '';
in

{
  # mutableExtensionsDir must remain incompatible with non-default profiles
  # that declare extensions, even though the default profile is exempt.
  programs.vscode = {
    enable = true;
    inherit package;
    mutableExtensionsDir = true;
    profiles = {
      default = { };
      work.extensions = [ fakeExtension ];
    };
  };

  test.asserts.assertions.expected = [
    "programs.vscode.mutableExtensionsDir cannot be true if any non-default profile specifies extensions."
  ];
}
