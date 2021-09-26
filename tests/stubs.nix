{ config, lib, pkgs, ... }:

with lib;

let

  stubType = types.submodule ({ name, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        default = "dummy";
        description = "The stub package name.";
      };

      outPath = mkOption {
        type = types.nullOr types.str;
        default = "@${name}@";
        defaultText = "@\${name}@";
      };

      version = mkOption {
        type = types.nullOr types.str;
        default = null;
      };

      buildScript = mkOption {
        type = types.str;
        default = defaultBuildScript;
      };
    };
  });

  defaultBuildScript = "mkdir $out";

  dummyPackage = pkgs.runCommandLocal "dummy" { } defaultBuildScript;

  mkStubPackage = { name ? "dummy", outPath ? null, version ? null
    , buildScript ? defaultBuildScript }:
    let
      pkg = if name == "dummy" && buildScript == defaultBuildScript then
        dummyPackage
      else
        pkgs.runCommandLocal name { } buildScript;
    in pkg // optionalAttrs (outPath != null) { inherit outPath; }
    // optionalAttrs (version != null) { inherit version; };

in {
  options.test.stubs = mkOption {
    type = types.attrsOf stubType;
    default = { };
    description =
      "Package attributes that should be replaced by a stub package.";
  };

  config = {
    lib.test.mkStubPackage = mkStubPackage;

    nixpkgs.overlays = mkIf (config.test.stubs != { })
      [ (self: super: mapAttrs (n: mkStubPackage) config.test.stubs) ];
  };
}
