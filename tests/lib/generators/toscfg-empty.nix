{ config, lib, ... }:

{
  home.file."toscfg-empty-result.txt".text = lib.hm.generators.toSCFG { } { };

  nmt.script = ''
    assertFileContent \
      home-files/toscfg-empty-result.txt \
      ${./toscfg-empty-result.txt}
  '';
}
