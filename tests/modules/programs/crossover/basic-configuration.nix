{ pkgs, ... }:
{
  programs.crossover = {
    enable = true;
    # The real derivation downloads the (unfree) CodeWeavers rpm; the test
    # only exercises the module wiring, so stand in a trivial package.
    package = pkgs.writeTextDir "bin/crossover" "";
    license = {
      file = pkgs.writeText "license.txt" "license";
      signature = pkgs.writeText "license.sha256" "signature";
    };
  };

  nmt.script = ''
    assertFileExists home-path/bin/crossover
    assertFileContent home-files/.cxoffice/etc/license.txt ${pkgs.writeText "expected-license.txt" "license"}
    assertFileContent home-files/.cxoffice/etc/license.sha256 ${pkgs.writeText "expected-signature.txt" "signature"}
  '';
}
