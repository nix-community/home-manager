{ config, lib, ... }:

{
  home.file."toscfg-err-dir-empty-name-result.txt".text =
    lib.hm.generators.toSCFG { } { "" = [ ]; };

  nmt.script = ''
    assertFileContent \
      home-files/toscfg-err-dir-empty-name-result.txt \
      ${./toscfg-err-dir-empty-name-result.txt}
  '';
}
