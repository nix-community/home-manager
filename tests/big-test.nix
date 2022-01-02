{ lib, ... }:

{
  options.test.enableBig = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Whether to enable <quote>big</quote> tests. These are tests that require
      more resources than typical tests. For example, tests that depend on large
      packages or tests that take long to run.
    '';
  };
}
