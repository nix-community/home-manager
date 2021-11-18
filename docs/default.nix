{ pkgs

# Note, this should be "the standard library" + HM extensions.
, lib ? import ../modules/lib/stdlib-extended.nix pkgs.lib }:

let

  nmdSrc = pkgs.fetchFromGitLab {
    name = "nmd";
    owner = "rycee";
    repo = "nmd";
    rev = "527245ff605bde88c2dd2ddae21c6479bb7cf8aa";
    sha256 = "1zi0f9y3wq4bpslx1py3sfgrgd9av41ahpandvs6rvkpisfsqqlp";
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
    modules = let
      nixosModule = module: pkgs.path + "/nixos/modules" + module;
      mockedNixos = with lib; {
        options = {
          environment.pathsToLink = mkSinkUndeclaredOptions { };
          systemd.services = mkSinkUndeclaredOptions { };
          users.users = mkSinkUndeclaredOptions { };
        };
      };
    in [
      ../nixos/default.nix
      mockedNixos
      (nixosModule "/misc/assertions.nix")
      scrubbedPkgsModule
    ];
    docBook = {
      id = "nixos-options";
      optionIdPrefix = "nixos-opt";
    };
  };

  nixDarwinModuleDocs = buildModulesDocs {
    modules = let
      nixosModule = module: pkgs.path + "/nixos/modules" + module;
      mockedNixDarwin = with lib; {
        options = {
          environment.pathsToLink = mkSinkUndeclaredOptions { };
          system.activationScripts.postActivation.text =
            mkSinkUndeclaredOptions { };
          users.users = mkSinkUndeclaredOptions { };
        };
      };
    in [
      ../nix-darwin/default.nix
      mockedNixDarwin
      (nixosModule "/misc/assertions.nix")
      scrubbedPkgsModule
    ];
    docBook = {
      id = "nix-darwin-options";
      optionIdPrefix = "nix-darwin-opt";
    };
  };

  docs = nmd.buildDocBookDocs {
    pathName = "home-manager";
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
}
