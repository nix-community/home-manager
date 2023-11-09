{ lib, ... }: {
  home.file."result.txt".text = lib.hm.generators.toKDL { } {
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
    nested = [ [ 1 2 ] [ true false ] [ ] [ null ] ];
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
    literalNodes = [
      {
        _name = "node";
        _args = [ "arg1" "arg2" ];
        _props = {
          prop1 = 1;
          prop2 = 2;
        };
        child1 = [ ];
        child2 = [ ];
      }
      {
        _name = "node";
        _args = [ "arg2" ];
        _props = {
          prop1 = 1;
          prop2 = 2;
        };
        child1 = [ ];
        child2 = [ ];
      }
      {
        _name = "node";
        _args = [ "arg2" ];
        _props = { prop2 = 2; };
        child1 = [ ];
        child2 = [ ];
      }
    ];
    listInAttrsInList = {
      list1 = [
        { a = 1; }
        { b = true; }
        {
          c = null;
          d = [{ e = "asdfadfasdfasdf"; }];
        }
      ];
      list2 = [{ a = 8; }];
    };
    zellijExampleSettings = {
      theme = "custom";
      themes.custom.fg = "#ffffff";
      keybinds = {
        _props = { clear-defaults = true; };
        normal = [
          {
            _name = "bind";
            _args = [ "Ctrl q" "Alt F4" ];
            Quit = [ ];
          }
          {
            _name = "bind";
            _args = [ "Alt l" ];
            MoveFocusOrTab = "Right";
          }
        ];
        locked = [
          {
            _name = "bind";
            _args = [ "Ctrl q" "Alt F4" ];
            Quit = [ ];
          }
          {
            _name = "bind";
            _args = [ "Alt l" ];
            MoveFocusOrTab = "Right";
          }
        ];
      };
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/result.txt \
      ${./tokdl-result.txt}
  '';
}
