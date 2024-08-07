{ config, lib, ... }: {
  home.file = {
    "tokdl-result.txt".text = lib.hm.generators.toKDL { } {
      a = 1;
      b = "string";
      c = ''
        multiline string
        with special characters:
        \t \n \" "
      '';
      unsafeString = " \" \n 	 ";
      flatItems = [ 1 2 "asdf" true null ];
      bigFlatItems = [
        23847590283751
        1.239
        ''
          multiline " " "
          string
        ''
        null
      ];
      repeated = [ [ 1 2 ] [ true false ] [ ] [ null ] ];
      extraAttrs = {
        _args = [ 2 true ];
        _props = {
          arg1 = 1;
          arg2 = false;
        };
        nested = {
          a = 1;
          b = null;
        };
      };
      listInAttrsInList = {
        list1."-" = [
          { a = 1; }
          { b = true; }
          {
            c = null;
            d."-" = [{ e = "asdfadfasdfasdf"; }];
          }
        ];
        list2 = [{ a = 8; }];
      };
    };
    "tokdl-attrs.txt".text = lib.hm.generators.toKDL { } {
      resize.bind = [
        {
          _args = [ "k" "Up" ];
          Resize = "Increase Up";
        }
        {
          _args = [ "j" "Down" ];
          Resize = "Increase Down";
        }
      ];
    };
    "tokdl-list.txt".text = lib.hm.generators.toKDL { } {
      resize.bind."-" = [
        {
          _args = [ "k" "Up" ];
          Resize = "Increase Up";
        }
        {
          _args = [ "j" "Down" ];
          Resize = "Increase Down";
        }
      ];
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/tokdl-attrs.txt \
      ${./tokdl-attrs.txt}
    assertFileContent \
      home-files/tokdl-list.txt \
      ${./tokdl-list.txt}
    assertFileContent \
      home-files/tokdl-result.txt \
      ${./tokdl-result.txt}
  '';
}
