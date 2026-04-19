{ config, lib, ... }:
let
  inherit (lib)
    concatStringsSep
    mkOption
    mkEnableOption
    types
    ;
in
{
  options.test.asserts = {
    warnings = {
      enable = mkEnableOption "warning asserts" // {
        default = true;
      };

      expected = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          List of expected warnings.
        '';
      };
    };

    assertions = {
      enable = mkEnableOption "assertion asserts" // {
        default = true;
      };

      expected = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          List of expected assertions.
        '';
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.test.asserts.warnings.enable {
      home.file = {
        "asserts/warnings.actual".text = concatStringsSep ''

          --
        '' config.warnings;
        "asserts/warnings.expected".text = concatStringsSep ''

          --
        '' config.test.asserts.warnings.expected;
      };

      nmt.script = ''
        assertFileContent \
          home-files/asserts/warnings.actual \
          "$TESTED/home-files/asserts/warnings.expected"
      '';
    })

    (lib.mkIf config.test.asserts.assertions.enable {
      home.file = {
        "asserts/assertions.actual".text = concatStringsSep ''

          --
        '' (map (x: x.message) (lib.filter (x: !x.assertion) config.assertions));
        "asserts/assertions.expected".text = concatStringsSep ''

          --
        '' config.test.asserts.assertions.expected;
      };

      nmt.script = ''
        assertFileContent \
          home-files/asserts/assertions.actual \
          "$TESTED/home-files/asserts/assertions.expected"
      '';
    })
  ];
}
