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
  };

  config = mkIf config.test.asserts.warnings.enable {
    home.file = {
      "asserts/warnings.actual".text = concatStringsSep ''

        --
      '' config.warnings;
    };

    nmt.script = ''
      assertFileContent \
        home-files/asserts/warnings.actual \
        ${
          pkgs.writeText "warnings.expected" (concatStringsSep ''

            --
          '' config.test.asserts.warnings.expected)
        }
    '';
  };
}
