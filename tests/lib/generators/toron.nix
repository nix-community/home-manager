{ config, lib, ... }:

{
  home.file."toron-result.ron".text = lib.hm.generators.toRON { } [
    # numbers
    {
      byte = {
        _type = "char";
        _name = "b";
        _value = "0";
      };
      # TODO: nix adds several trailing zeros to floats, is that an issue?
      float_exp = {
        _value = -1.0;
        _suffix = "e-16";
      };
      # while nix supports fractional notation, nix fmt will complain about .1
      # that said, consumers of RON shouldn't need fractional notation
      float_frac = { _name = ".1"; };
      float_int = 1000;
      # TODO: nix adds several trailing zeros to floats, is that an issue?
      float_std = 1000.0;
      float_suffix = { _name = "-.1f64"; };
      integer = 0;
      integer_suffix = {
        _name = "i";
        _value = 8;
      };
      unsigned_binary = {
        _name = "0b";
        _value = 10;
      };
      unsigned_decimal = 10;
      unsigned_hexadecimal = {
        _type = "hex";
        _name = "0x";
        _value = "FF";
      };
      unsigned_octal = {
        _name = "0o";
        _value = 10;
      };
    }
    # chars
    {
      char = {
        _type = "char";
        _value = "a";
      };
    }
    # strings
    {
      byte_string_raw = {
        _name = "br##";
        _value = "Hello, World!";
        _suffix = "##";
      };
      byte_string_std = {
        _name = "b";
        _value = "Hello, World!";
      };
      string_escape_ascii = "\\'";
      string_escape_byte = "\\x0A";
      string_escape_unicode = "\\u{0A0A}";
      string_raw = {
        _name = "r##";
        _value = ''
          This is a "raw string".
          It can contain quotations or backslashes\!'';
        _suffix = "##";
      };
      string_std = "Hello, World!";
    }
    # boolean
    {
      boolean = true;
    }
    # option/enum
    {
      enum_nested = {
        _type = "enum";
        _name = "Some";
        _value = {
          _type = "enum";
          _name = "Some";
          _value = 10;
        };
      };
      option_none_explicit = {
        _type = "enum";
        _name = "None";
        _value = null;
      };
      option_none_implicit = {
        _name = "None";
      };
      option_some = {
        _type = "enum";
        _name = "Some";
        _value = 10;
      };
    }
    # list
    {
      list = [ 1 2 3 ];
    }
    # map
    {
      map_explicit = {
        _type = "map";
        _value = {
          a = 1;
          b = 2;
          c = 3;
        };
      };
      map_implicit = {
        a = 1;
        b = 2;
        c = 3;
      };
    }
    # tuple
    {
      tuple = {
        _type = "tuple";
        _value = [ 1 2 3 ];
      };
    }
    # struct
    {
      named_struct_explicit = {
        _name = "NamedStruct";
        _type = "struct";
        _value = {
          a = 1;
          b = 2;
          c = 3;
        };
      };
      named_struct_implicit = {
        _name = "NamedStruct";
        _value = {
          a = 1;
          b = 2;
          c = 3;
        };
      };
      tuple_struct_explicit = {
        _type = "tuple";
        _name = "TupleStruct";
        _value = [ 1 2 3 ];
      };
      tuple_struct_implicit = {
        _name = "TupleStruct";
        _value = [ 1 2 3 ];
      };
      unit_struct = {
        _type = "struct";
        _value = [ ];
      };
      unit_struct_ident = { _name = "MyUnitStruct"; };
    }
  ];

  nmt.script = ''
    assertFileContent \
      home-files/toron-result.ron \
      ${./toron-result.ron}
  '';
}
