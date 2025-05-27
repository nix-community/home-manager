{ lib, ... }:

{
  options.test.enableBig = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Whether to enable "big" tests. These are tests that require
      more resources than typical tests. For example, tests that depend on large
      packages or tests that take long to run.
    '';
  };

  options.test.enableLegacyIfd = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Whether to enable tests that use import-from-derivation (IFD). Use of IFD
      in Home Manager is deprecated, and this option should not be used for new
      tests.
    '';
  };
}
