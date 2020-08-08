{ config, lib, pkgs, ... }:

with lib;

let

in {
  options.examples = mkOption { type = types.attrsOf hm.types.gvariant; };

  config = {
    examples = with hm.gvariant;
      mkMerge [
        { bool = true; }
        { bool = true; }

        { float = 3.14; }

        { int = 42; }
        { int = 42; }

        { list = [ "one" ]; }
        { list = mkArray type.string [ "two" ]; }

        { emptyArray1 = [ ]; }
        { emptyArray2 = mkEmptyArray type.uint32; }

        { string = "foo"; }
        { string = "foo"; }
        { escapedString = "' \\"; }

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
            bool = true
            emptyArray1 = @as []
            emptyArray2 = @as []
            escapedString = '\' \\'
            float = 3.140000
            int = 42
            list = @as ['one','two']
            maybe1 = @ms nothing
            maybe2 = just @u 4
            string = 'foo'
            tuple = @(ias) (1,@as ['foo'])
          ''
        }
    '';
  };
}
