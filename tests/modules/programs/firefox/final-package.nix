modulePath:
{
  config,
  lib,
  realPkgs,
  ...
}:

let

  cfg = lib.getAttrFromPath modulePath config;

in
lib.mkIf config.test.enableBig (
  lib.setAttrByPath modulePath {
    enable = true;
  }
  // {
    _module.args.pkgs = lib.mkForce realPkgs;

    nmt.script = ''
      package=${cfg.package}
      finalPackage=${cfg.finalPackage}
      if [[ $package != $finalPackage ]]; then
        fail "Expected finalPackage ($finalPackage) to equal package ($package)"
      fi
    '';
  }
)
