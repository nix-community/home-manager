{ pkgs

# Note, this should be "the standard library" + HM extensions.
, lib ? import ../modules/lib/stdlib-extended.nix pkgs.lib }:

let

  nmdSrc = fetchTarball {
    url =
      "https://git.sr.ht/~rycee/nmd/archive/abb15317ebd17e5a0a7dd105e2ce52f2700185a8.tar.gz";
    sha256 = "0zzrbjxf15hada279irif7s3sb8vs95jn4y4f8694as0j739gd1m";
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
