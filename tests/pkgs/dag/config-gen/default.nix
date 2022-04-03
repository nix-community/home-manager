{ lib, pkgs, ... }:

{
  nmt.script = ''
    assertFileContent ${
      pkgs.hm.dag.toCborFile "config.cbor" null {
        bar = lib.hm.dag.entryAnywhere "second";
        foo = lib.hm.dag.entryBefore [ "bar" ] "first";
      }
    } ${./config.cbor}

    assertFileContent ${
      pkgs.hm.dag.toJsonFile "config.json" 2 {
        i = {
          can = lib.hm.dag.entryBefore [ "be" ] "reached here but not";
          be = lib.hm.dag.entryAnywhere {
            over = lib.hm.dag.entryAnywhere "here";
          };
        };
      }
    } ${./config.json}

    assertFileContent ${
      pkgs.hm.dag.toMessagePackFile "config.msgpack" 1 {
        this = lib.hm.dag.entryAnywhere 0;
        order = lib.hm.dag.entryBetween [ "is" ] [ "this" ] 1;
        is = lib.hm.dag.entryAnywhere { preserved = 2; };
      }
    } ${./config.msgpack}

    assertFileContent ${
      pkgs.hm.dag.toTomlFile "config.toml" 3 {
        directory.substitutions = {
          "/a/b" = lib.hm.dag.entryAnywhere "b";
          "/a" = lib.hm.dag.entryAfter [ "/a/b" ] "a";
        };
      }
    } ${./config.toml}

    assertFileContent ${
      pkgs.hm.dag.toYamlFile "config.yaml" null {
        nested = lib.hm.dag.entryBefore [ "work" ] {
          dags = lib.hm.dag.entryBefore [ "should" ] null;
          should = lib.hm.dag.entryAnywhere "also";
        };
        work = lib.hm.dag.entryAfter [ "nested" ] [ 0 "1" 2 ];
      }
    } ${./config.yaml}
  '';
}
