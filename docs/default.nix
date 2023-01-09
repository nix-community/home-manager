{ pkgs

# Note, this should be "the standard library" + HM extensions.
, lib ? import ../modules/lib/stdlib-extended.nix pkgs.lib }:

let

  nmdSrc = fetchTarball {
    url =
      "https://gitlab.com/api/v4/projects/rycee%2Fnmd/repository/archive.tar.gz?sha=06c80103396a1a950586c23da1882c977b24bbda";
    sha256 = "15axmplkl7m7fs4c8m53dawhgwkb64hm2v67m59xdknbjjgfrpqb";
  };

  nmd = import nmdSrc { inherit lib pkgs; };

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

  buildModulesDocs = args:
    nmd.buildModulesDocs ({
      moduleRootPaths = [ ./.. ];
      mkModuleUrl = path:
        "https://github.com/nix-community/home-manager/blob/master/${path}#blob-path";
      channelName = "home-manager";
    } // args);

  hmModulesDocs = buildModulesDocs {
    modules = import ../modules/modules.nix {
      inherit lib pkgs;
      check = false;
    } ++ [ scrubbedPkgsModule ];
    docBook.id = "home-manager-options";
  };

  nixosModuleDocs = buildModulesDocs {
    modules = [ ../nixos scrubbedPkgsModule dontCheckDefinitions ];
    docBook = {
      id = "nixos-options";
      optionIdPrefix = "nixos-opt";
    };
  };

  nixDarwinModuleDocs = buildModulesDocs {
    modules = [ ../nix-darwin scrubbedPkgsModule dontCheckDefinitions ];
    docBook = {
      id = "nix-darwin-options";
      optionIdPrefix = "nix-darwin-opt";
    };
  };

  docs = nmd.buildDocBookDocs {
    pathName = "home-manager";
    projectName = "Home Manager";
    modulesDocs = [ hmModulesDocs nixDarwinModuleDocs nixosModuleDocs ];
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
    json = hmModulesDocs.json.override {
      path = "share/doc/home-manager/options.json";
    };
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
