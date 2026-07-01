{ config, pkgs, ... }:
let
  wayleTestLib = import ./lib.nix { inherit config pkgs; };
  inherit (wayleTestLib.asserts) awwwInstalled packageInstalled;
in
{
  services.wayle = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "wayle"; };
    settings = { };
    autoInstallDependencies = false;
  };

  # When services.wayle.settings = {}, we expect that no config file is
  # created.
  nmt.script = ''
    assertPathNotExists "home-files/.config/wayle/config.toml"
  '';

  # When services.wayle.autoInstallDependencies = false, we expect that none of
  # wayles dependencies are installed.
  assertions = [
    (awwwInstalled false)
    (packageInstalled "matugen" false)
    (packageInstalled "wallust" false)
    (packageInstalled "pywal" false)
  ];
}
