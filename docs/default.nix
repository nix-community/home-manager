{ pkgs

# Note, this should be "the standard library" + HM extensions.
, lib ? import ../modules/lib/stdlib-extended.nix pkgs.lib

, release, isReleaseBranch }:

let

  nmdSrc = fetchTarball {
    url =
      "https://git.sr.ht/~rycee/nmd/archive/824a380546b5d0d0eb701ff8cd5dbafb360750ff.tar.gz";
    sha256 = "0vvj40k6bw8ssra8wil9rqbsznmfy1kwy7cihvm13rajwdg9ycgg";
  };

  nmd = import nmdSrc {
    inherit lib;
    # The DocBook output of `nixos-render-docs` doesn't have the change
    # `nmd` uses to work around the broken stylesheets in
    # `docbook-xsl-ns`, so we restore the patched version here.
    pkgs = pkgs // {
      docbook-xsl-ns =
        pkgs.docbook-xsl-ns.override { withManOptDedupPatch = true; };
    };
  };

  # Make sure the used package is scrubbed to avoid actually
  # instantiating derivations.
  scrubbedPkgsModule = {
    imports = [{
      _module.args = {
        pkgs = lib.mkForce (nmd.scrubDerivations "pkgs" pkgs);
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
    let options = (lib.evalModules { inherit modules; }).options;
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

  docs = nmd.buildDocBookDocs {
    pathName = "home-manager";
    projectName = "Home Manager";
    modulesDocs = [{
      docBook = pkgs.linkFarm "hm-module-docs-for-nmd" {
        "nmd-result/home-manager-options.xml" = hmOptionsDocs.optionsDocBook;
        "nmd-result/nix-darwin-options.xml" =
          nixDarwinOptionsDocs.optionsDocBook;
        "nmd-result/nixos-options.xml" = nixosOptionsDocs.optionsDocBook;
      };
    }];
    documentsDirectory = ./.;
    documentType = "book";
    chunkToc = ''
      <toc>
        <d:tocentry xmlns:d="http://docbook.org/ns/docbook" linkend="book-home-manager-manual"><?dbhtml filename="index.html"?>
          <d:tocentry linkend="ch-options"><?dbhtml filename="options.html"?></d:tocentry>
          <d:tocentry linkend="ch-nixos-options"><?dbhtml filename="nixos-options.html"?></d:tocentry>
          <d:tocentry linkend="ch-nix-darwin-options"><?dbhtml filename="nix-darwin-options.html"?></d:tocentry>
          <d:tocentry linkend="ch-tools"><?dbhtml filename="tools.html"?></d:tocentry>
          <d:tocentry linkend="ch-release-notes"><?dbhtml filename="release-notes.html"?></d:tocentry>
        </d:tocentry>
      </toc>
    '';
  };

in {
  inherit nmdSrc;

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
        --replace \
          '${hmOptionsDocs.optionsJSON}/share/doc/nixos' \
          "$out/share/doc/home-manager"
    '';
  };

  manPages = docs.manPages;

  manual = { inherit (docs) html htmlOpenTool; };

  # Unstable, mainly for CI.
  jsonModuleMaintainers = pkgs.writeText "hm-module-maintainers.json" (let
    result = lib.evalModules {
      modules = import ../modules/modules.nix {
        inherit lib pkgs;
        check = false;
      } ++ [ scrubbedPkgsModule ];
    };
  in builtins.toJSON result.config.meta.maintainers);
}
