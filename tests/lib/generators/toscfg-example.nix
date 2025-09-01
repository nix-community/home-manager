{ lib, ... }:

{
  home.file."toscfg-example-result.txt".text = lib.hm.generators.toSCFG { } (
    lib.singleton {
      name = "dir";
      children = lib.singleton {
        name = "blk1";
        params = [
          "p1"
          ''"p2"''
        ];
        children = [
          {
            name = "sub1";
            params = [
              "arg11"
              "arg12"
            ];
          }
          {
            name = "sub2";
            params = [
              "arg21"
              "arg22"
            ];
          }
          {
            name = "sub2";
            params = [
              "arg1"
              "arg2"
            ];
          }
          {
            name = "sub3";
            params = [
              "arg31"
              "arg32"
            ];
            children = [
              { name = "sub sub1"; }
              {
                name = "sub-sub2";
                params = [
                  "arg321"
                  "arg322"
                ];
              }
            ];
          }
        ];
      };
    }
  );

  nmt.script = ''
    assertFileContent \
      home-files/toscfg-example-result.txt \
      ${./toscfg-example-result.txt}
  '';
}
