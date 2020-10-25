{ pkgs

# Note, this should be "the standard library" + HM extensions.
, lib ? import ../modules/lib/stdlib-extended.nix pkgs.lib }:

let

  nmdSrc = pkgs.fetchFromGitLab {
    name = "nmd";
    owner = "rycee";
    repo = "nmd";
    rev = "2398aa79ab12aa7aba14bc3b08a6efd38ebabdc5";
    sha256 = "0yxb48afvccn8vvpkykzcr4q1rgv8jsijqncia7a5ffzshcrwrnh";
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

  hmModulesDocs = nmd.buildModulesDocs {
    modules = import ../modules/modules.nix {
      inherit lib pkgs;
      check = false;
    } ++ [ scrubbedPkgsModule ];
    moduleRootPaths = [ ./.. ];
    mkModuleUrl = path:
      "https://github.com/nix-community/home-manager/blob/master/${path}#blob-path";
    channelName = "home-manager";
    docBook.id = "home-manager-options";
  };

  docs = nmd.buildDocBookDocs {
    pathName = "home-manager";
    modulesDocs = [ hmModulesDocs ];
    documentsDirectory = ./.;
    documentType = "book";
    chunkToc = ''
      <toc>
        <d:tocentry xmlns:d="http://docbook.org/ns/docbook" linkend="book-home-manager-manual"><?dbhtml filename="index.html"?>
          <d:tocentry linkend="ch-options"><?dbhtml filename="options.html"?></d:tocentry>
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
}
