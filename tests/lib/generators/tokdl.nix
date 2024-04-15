{ lib, ... }: {
  home.file."tokdl-result.txt".text = lib.hm.generators.toKDL { } [
    {
      name = "a";
      args = 1;
    }
    {
      name = "b";
      args = "string";
    }
    {
      name = "c";
      args = ''
        multiline string
        with special characters:
        \t \n \" "
      '';
    }
    {
      name = "unsafeString";
      args = " \" \n 	 ";
    }
    {
      name = "flatItems";
      args = [ 1 2 "asdf" true null ];
    }
    {
      name = "bigFlatItems";
      args = [
        23847590283751
        1.239
        ''
          multiline " " "
          string
        ''
        null
      ];
    }
    {
      name = "repeated";
      args = [ 1 2 ];
    }
    {
      name = "repeated";
      args = [ true false ];
    }
    { name = "repeated"; }
    {
      name = "repeated";
      args = [ null ];
    }
    {
      name = "extraAttrs";
      args = [ 2 true ];
      props = {
        arg1 = 1;
        arg2 = false;
      };
      children = {
        name = "nested";
        children = [
          {
            name = "a";
            args = [ 1 ];
          }
          {
            name = "b";
            args = [ null ];
          }
        ];
      };
    }
    {
      name = "listInAttrsInList";
      children = [
        {
          name = "list1";
          children = [
            {
              name = "-";
              children = {
                name = "a";
                args = [ 1 ];
              };
            }
            {
              name = "-";
              children = {
                name = "b";
                args = [ true ];
              };
            }
            {
              name = "-";
              children = [
                {
                  name = "c";
                  args = [ null ];
                }
                {
                  name = "d";
                  children = {
                    name = "-";
                    children = {
                      name = "e";
                      args = [ "asdfadfasdfasdf" ];
                    };
                  };
                }
              ];
            }
          ];
        }
        {
          name = "list2";
          children = [{
            name = "a";
            args = [ 8 ];
          }];
        }
      ];
    }
  ];

  nmt.script = ''
    assertFileContent \
      home-files/tokdl-result.txt \
      ${./tokdl-result.txt}
  '';
}
