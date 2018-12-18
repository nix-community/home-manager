{ pkgs }:

let

  lib = pkgs.lib;

  nmdSrc = pkgs.fetchFromGitLab {
    owner = "rycee";
    repo = "nmd";
    rev = "b57fc6657b6645086a286e62a05a1795f258daa6";
    sha256 = "1b6bdgn6d4awxi8al5hbw8vycxp4laf63l29rjrvxi2j2g69rgvc";
  };

  nmd = import nmdSrc { inherit pkgs; };

  hmModulesDocs = nmd.buildModulesDocs {
    modules = import ../modules/modules.nix { inherit lib pkgs; };
    moduleRootPaths = [ ./.. ];
    mkModuleUrl = path:
      "https://github.com/rycee/home-manager/blob/master/${path}#blob-path";
    channelName = "home-manager";
    docBook.id = "home-manager-options";
  };

  docs = nmd.buildDocBookDocs {
    pathName = "home-manager";
    modulesDocs = [ hmModulesDocs ];
    documentsDirectory = ./.;
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

in

{

  options = {
    json = hmModulesDocs.json.override {
      path = "share/doc/home-manager/options.json";
    };
  };

  manPages = docs.manPages;

  manual = {
    inherit (docs) html htmlOpenTool;
  };

}
