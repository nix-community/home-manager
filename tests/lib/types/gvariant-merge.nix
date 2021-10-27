{ config, lib, pkgs, ... }:

let inherit (lib) concatStringsSep hm mapAttrsToList mkMerge mkOption types;
in {
  options.examples = mkOption { type = types.attrsOf hm.types.gvariant; };

  config = {
    examples = with hm.gvariant;
      mkMerge [
        { bool = true; }
        { bool = true; }

        { float = 3.14; }

        { int = -42; }
        { int = -42; }

        { uint32 = mkUint32 42; }
        { uint32 = mkUint32 42; }

        { int16 = mkInt16 (-42); }
        { int16 = mkInt16 (-42); }

        { uint16 = mkUint16 42; }
        { uint16 = mkUint16 42; }

        { int64 = mkInt64 (-42); }
        { int64 = mkInt64 (-42); }

        { uint64 = mkUint64 42; }
        { uint64 = mkUint64 42; }

        { array1 = [ "one" ]; }
        { array1 = mkArray type.string [ "two" ]; }
        { array2 = mkArray type.uint32 [ 1 ]; }
        { array2 = mkArray type.uint32 [ 2 ]; }

        { emptyArray1 = [ ]; }
        { emptyArray2 = mkEmptyArray type.uint32; }

        { string = "foo"; }
        { string = "foo"; }
        {
          escapedString = ''
            '\
          '';
        }

        { tuple = mkTuple [ 1 [ "foo" ] ]; }

        { maybe1 = mkNothing type.string; }
        { maybe2 = mkJust (mkUint32 4); }
      ];

    home.file."result.txt".text = let
      mkLine = n: v: "${n} = ${toString (hm.gvariant.mkValue v)}";
      result = concatStringsSep "\n" (mapAttrsToList mkLine config.examples);
    in result + "\n";

    nmt.script = ''
      assertFileContent \
        home-files/result.txt \
        ${
          pkgs.writeText "expected.txt" ''
            array1 = @as ['one','two']
            array2 = @au [1,2]
            bool = true
            emptyArray1 = @as []
            emptyArray2 = @au []
            escapedString = '\'\\\n'
            float = 3.140000
            int = -42
            int16 = @n -42
            int64 = @x -42
            maybe1 = @ms nothing
            maybe2 = just @u 4
            string = 'foo'
            tuple = @(ias) (1,@as ['foo'])
            uint16 = @q 42
            uint32 = @u 42
            uint64 = @t 42
          ''
        }
    '';
  };
}
