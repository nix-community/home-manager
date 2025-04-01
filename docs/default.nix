{ pkgs

# Note, this should be "the standard library" + HM extensions.
, lib ? import ../modules/lib/stdlib-extended.nix pkgs.lib

, release, isReleaseBranch }:

let

  # Recursively replace each derivation in the given attribute set
  # with the same derivation but with the `outPath` attribute set to
  # the string `"\${pkgs.attribute.path}"`. This allows the
  # documentation to refer to derivations through their values without
  # establishing an actual dependency on the derivation output.
  #
  # This is not perfect, but it seems to cover a vast majority of use
  # cases.
  #
  # Caveat: even if the package is reached by a different means, the
  # path above will be shown and not e.g.
  # `${config.services.foo.package}`.
  scrubDerivations = prefixPath: attrs:
    let
      scrubDerivation = name: value:
        let pkgAttrName = prefixPath + "." + name;
        in if lib.isAttrs value then
          scrubDerivations pkgAttrName value
          // lib.optionalAttrs (lib.isDerivation value) {
            outPath = "\${${pkgAttrName}}";
          }
        else
          value;
    in lib.mapAttrs scrubDerivation attrs;

  # Make sure the used package is scrubbed to avoid actually
  # instantiating derivations.
  scrubbedPkgsModule = {
    imports = [{
      _module.args = {
        pkgs = lib.mkForce (scrubDerivations "pkgs" pkgs);
        pkgs_i686 = lib.mkForce { };
      };
    }];
  };

  dontCheckDefinitions = { _module.check = false; };

  gitHubDeclaration = user: repo: subpath:
    let urlRef = if isReleaseBranch then "release-${release}" else "master";
    in {
      url = "https://github.com/${user}/${repo}/blob/${urlRef}/${subpath}";
      name = "<${repo}/${subpath}>";
    };

  hmPath = toString ./..;

  buildOptionsDocs = args@{ modules, includeModuleSystemOptions ? true, ... }:
    let
      options = (lib.evalModules {
        inherit modules;
        class = "homeManager";
      }).options;
    in pkgs.buildPackages.nixosOptionsDoc ({
      options = if includeModuleSystemOptions then
        options
      else
        builtins.removeAttrs options [ "_module" ];
      transformOptions = opt:
        opt // {
          # Clean up declaration sites to not refer to the Home Manager
          # source tree.
          declarations = map (decl:
            if lib.hasPrefix hmPath (toString decl) then
              gitHubDeclaration "nix-community" "home-manager"
              (lib.removePrefix "/" (lib.removePrefix hmPath (toString decl)))
            else if decl == "lib/modules.nix" then
            # TODO: handle this in a better way (may require upstream
            # changes to nixpkgs)
              gitHubDeclaration "NixOS" "nixpkgs" decl
            else
              decl) opt.declarations;
        };
    } // builtins.removeAttrs args [ "modules" "includeModuleSystemOptions" ]);

  hmOptionsDocs = buildOptionsDocs {
    modules = import ../modules/modules.nix {
      inherit lib pkgs;
      check = false;
    } ++ [ scrubbedPkgsModule ];
    variablelistId = "home-manager-options";
  };

  nixosOptionsDocs = buildOptionsDocs {
    modules = [ ../nixos scrubbedPkgsModule dontCheckDefinitions ];
    includeModuleSystemOptions = false;
    variablelistId = "nixos-options";
    optionIdPrefix = "nixos-opt-";
  };

  nixDarwinOptionsDocs = buildOptionsDocs {
    modules = [ ../nix-darwin scrubbedPkgsModule dontCheckDefinitions ];
    includeModuleSystemOptions = false;
    variablelistId = "nix-darwin-options";
    optionIdPrefix = "nix-darwin-opt-";
  };

  release-config = builtins.fromJSON (builtins.readFile ../release.json);
  revision = "release-${release-config.release}";
  # Generate the `man home-configuration.nix` package
  home-configuration-manual =
    pkgs.runCommand "home-configuration-reference-manpage" {
      nativeBuildInputs =
        [ pkgs.buildPackages.installShellFiles pkgs.nixos-render-docs ];
      allowedReferences = [ "out" ];
    } ''
      # Generate manpages.
      mkdir -p $out/share/man/man5
      mkdir -p $out/share/man/man1
      nixos-render-docs -j $NIX_BUILD_CORES options manpage \
        --revision ${revision} \
        --header ${./home-configuration-nix-header.5} \
        --footer ${./home-configuration-nix-footer.5} \
        ${hmOptionsDocs.optionsJSON}/share/doc/nixos/options.json \
        $out/share/man/man5/home-configuration.nix.5
      cp ${./home-manager.1} $out/share/man/man1/home-manager.1
    '';
  # Generate the HTML manual pages
  home-manager-manual = pkgs.callPackage ./home-manager-manual.nix {
    home-manager-options = {
      home-manager = hmOptionsDocs.optionsJSON;
      nixos = nixosOptionsDocs.optionsJSON;
      nix-darwin = nixDarwinOptionsDocs.optionsJSON;
    };
    inherit revision;
  };
  html = home-manager-manual;
  htmlOpenTool = pkgs.callPackage ./html-open-tool.nix { } { inherit html; };
in {
  options = {
    # TODO: Use `hmOptionsDocs.optionsJSON` directly once upstream
    # `nixosOptionsDoc` is more customizable.
    json = pkgs.runCommand "options.json" {
      meta.description = "List of Home Manager options in JSON format";
    } ''
      mkdir -p $out/{share/doc,nix-support}
      cp -a ${hmOptionsDocs.optionsJSON}/share/doc/nixos $out/share/doc/home-manager
      substitute \
        ${hmOptionsDocs.optionsJSON}/nix-support/hydra-build-products \
        $out/nix-support/hydra-build-products \
        --replace-fail \
          '${hmOptionsDocs.optionsJSON}/share/doc/nixos' \
          "$out/share/doc/home-manager"
    '';
  };

  manPages = home-configuration-manual;

  manual = { inherit html htmlOpenTool; };

  # Unstable, mainly for CI.
  jsonModuleMaintainers = pkgs.writeText "hm-module-maintainers.json" (let
    result = lib.evalModules {
      modules = import ../modules/modules.nix {
        inherit lib pkgs;
        check = false;
      } ++ [ scrubbedPkgsModule ];
      class = "homeManager";
    };
  in builtins.toJSON result.config.meta.maintainers);
}
