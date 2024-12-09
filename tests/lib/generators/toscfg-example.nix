{ config, lib, ... }:

{
  home.file."toscfg-example-result.txt".text = lib.hm.generators.toSCFG { } {
    dir = {
      blk1 = {
        _params = [ "p1" ''"p2"'' ];
        sub1 = [ "arg11" "arg12" ];
        sub2 = [ "arg21" "arg22" ];
        sub3 = {
          _params = [ "arg31" "arg32" ];
          sub-sub1 = [ ];
          sub-sub2 = [ "arg321" "arg322" ];
        };
      };
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/toscfg-example-result.txt \
      ${./toscfg-example-result.txt}
  '';
}
