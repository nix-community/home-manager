{ config, ... }:

let
  inherit (config.lib.test) mkStubPackage;
in

{
  programs.gram = {
    enable = true;
    package = null;
    extraPackages = [ (mkStubPackage { }) ];
  };

  test.asserts.assertions.expected = [
    ''
      The `programs.gram.extraPackages` option requires that `programs.gram.package`
      not be null.
    ''
  ];
}
