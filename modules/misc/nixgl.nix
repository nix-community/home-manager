{ config, pkgs, lib, ... }:

let
  cfg = config.targets.genericLinux.nixgl;

  # Expects a packageConfiguration hashset
  # Adapted from https://nixos.wiki/wiki/Nix_Cookbook
  wrapWithNixGL = pkgConfig:
    (let
      binary = if (builtins.hasAttr "binary" pkgConfig) then
        pkgConfig.binary
      else
        null;
      package = pkgConfig.package;

      bin = if binary == null then package.pname else binary;
      nixGL = import cfg.src { inherit pkgs; };
      wrapperPkg = lib.attrsets.getAttrFromPath cfg.wrapperPkgPath nixGL;
      wrapperBinPath = "${wrapperPkg}/bin/${cfg.wrapperBinName}";
    in pkgs.runCommand "nixgl-${package.pname}" {
      buildInputs = [ pkgs.makeWrapper ];
    } ''
      mkdir $out
      # Link every top-level folder from pkgs.hello to our new target
      ln -s ${package}/* $out
      # Except the bin folder
      rm $out/bin
      mkdir $out/bin
      # We create the bin folder ourselves and link every binary in it
      ln -s ${package}/bin/* $out/bin
      # Except the target binary
      rm $out/bin/${bin}
      # Because we create this ourself, by creating a wrapper
      makeWrapper ${wrapperBinPath} $out/bin/${bin} \
        --add-flags ${package}/bin/${bin}
    '');
  packageConfiguration = with lib;
    types.submodule {
      options = {
        binary = mkOption {
          type = types.nullOr types.str;
          example = "alacritty";
          default = null;
          description = ''
            Name of the binary in bin/ of the package.
            By default this uses `package.pname`.
          '';
        };
        package = mkOption {
          type = types.package;
          example = "pkgs.alacritty";
          description = ''
            The package to be wrapped.
            It's expected to have a `pname` attribute.
          '';
        };
      };
    };
in {
  meta.maintainers = with lib.maintainers; [ michaelCTS ];

  options.targets.genericLinux.nixgl = {

    src = lib.mkOption {
      type = lib.types.package;
      example = ''
        pkgs.fetchFromGithub {
          owner = "nix-community";
          repo = "nixGL";
          rev = "v1.3";
          hash = "SOMEHASH-HERE";
        }
      '';
      description = ''
        Path to a downloaded source of nixGL.
        You can download the nixGL version of your choice and point to it here.
      '';
    };

    wrapperBinName = lib.mkOption {
      type = lib.types.str;
      example = "nixGL";
      default = "nixGL";
      description =
        "Name of the nixGL binary to be called from within the wrapper package";
    };

    wrapperPkgPath = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      example = [ "auto" "nixGLNvidia" ];
      default = [ "auto" "nixGLDefault" ];
      description = "Attribute path within `src` attrset to the nixGL package";
    };

    packages = lib.mkOption {
      type = lib.types.listOf packageConfiguration;
      default = [ ];
      example = "[{ package = pkgs.alacritty; }]";
      description = ''
        List of packages that will be wrapped with nixGL in order to be able to use nixgl.
        Without the wrapper, graphical applications cannot access nixgl and thus have no
        graphical acceleration.
      '';
    };

  };

  config = {
    lib.nixGl.wrap = wrapWithNixGL;
    home.packages = builtins.map config.lib.nixGl.wrap
      config.targets.genericLinux.nixgl.packages;
  };

}

