{ config, lib, pkgs, ... }:

with lib;

{
  options.test.asserts = {
    warnings = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether warning asserts are enabled.";
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
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether assertion asserts are enabled.";
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

  config = mkIf config.test.asserts.warnings.enable {
    home.file = {
      "asserts/warnings.actual".text = concatStringsSep ''

        --
      '' config.warnings;

      "asserts/assertions.actual".text = concatStringsSep ''

        --
      '' (map (x: x.message) (filter (x: !x.assertion) config.assertions));
    };

    nmt.script = ''
      assertFileContent \
        home-files/asserts/warnings.actual \
        ${
          pkgs.writeText "warnings.expected" (concatStringsSep ''

            --
          '' config.test.asserts.warnings.expected)
        }

      assertFileContent \
        home-files/asserts/assertions.actual \
        ${
          pkgs.writeText "assertions.expected" (concatStringsSep ''

            --
          '' config.test.asserts.assertions.expected)
        }
    '';
  };
}
