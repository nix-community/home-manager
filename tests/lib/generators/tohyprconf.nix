{ lib, ... }:

{
  home.file."tohyprconf-result.txt".text = lib.hm.generators.toHyprconf {
    attrs = rec {
      "$important" = 123;

      list-section = [
        "foo"
        "bar"
        "baz"
      ];

      attrs-section = {
        string = "abc";
        int = 5;
        float = 0.8;
        bool = true;
        null = null;
      };

      nested-attrs-section = {
        a = {
          b = {
            c = {
              abc = 123;
            };
          };
        };

        foo = {
          bar = {
            baz = {
              aaa = 111;
            };
          };
        };
      };

      nested-list-section = [
        { a = 123; }
        { b = 123; }
        { c = 123; }
      ];

      combined-list-nested-section = [
        nested-attrs-section.a
        nested-attrs-section.foo
      ];

      combined-attrs-nested-section = {
        a = nested-list-section;
        b = nested-list-section;
      };

      list-with-strings-and-attrs = [
        "abc"
        { a = 123; }
        "foo"
        { b = 321; }
      ];
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/tohyprconf-result.txt \
      ${./tohyprconf-result.txt}
  '';
}
