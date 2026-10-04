package:

{ pkgs, ... }:

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
    assertPathNotExists "home-files/${
      if pkgs.stdenv.hostPlatform.isDarwin then
        "Library/Application Support/Code/User"
      else
        ".config/Code/User"
    }/profiles/work/extensions.json"
  '';
}
