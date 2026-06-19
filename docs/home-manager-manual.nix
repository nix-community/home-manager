{
  stdenv,
  lib,
  callPackage,
  mdbook,
  python3,
  revision,
  home-manager-options,
}:
let
  outputPath = "share/doc/home-manager";
  mdbookOptions = callPackage ./mdbook/options.nix {
    manpageUrls = ./manual/manpage-urls.json;
    inherit revision;
    optionDocs = {
      home-manager = {
        title = "Home Manager Configuration Options";
        path = "home-manager";
        prefix = "opt-";
        json = "${home-manager-options.home-manager.json}";
      };
      nixos = {
        title = "NixOS Configuration Options";
        path = "nixos";
        prefix = "nixos-opt-";
        json = "${home-manager-options.nixos.json}";
      };
      nix-darwin = {
        title = "nix-darwin Configuration Options";
        path = "nix-darwin";
        prefix = "nix-darwin-opt-";
        json = "${home-manager-options.nix-darwin.json}";
      };
    };
  };
in
stdenv.mkDerivation {
  name = "home-manager-manual";

  nativeBuildInputs = [
    mdbook
    python3
  ];

  src = ./.;

  buildPhase = ''
    runHook preBuild

    mkdir -p source
    python3 ${./mdbook/convert-markup.py} "$src/manual" source
    python3 ${./mdbook/convert-markup.py} \
      --base-depth 1 \
      "$src/release-notes" \
      source/release-notes

    cp -r ${mdbookOptions}/options source/options

    python3 ${./mdbook/substitute-summary.py} \
      source/SUMMARY.md \
      ${mdbookOptions}/summary/home-manager.md \
      ${mdbookOptions}/summary/nixos.md \
      ${mdbookOptions}/summary/nix-darwin.md

    mdbook build source --dest-dir book

    mkdir -p out
    cp -r book/* out/

    makeRedirect() {
      local target=$1
      local destination=$2
      printf '%s\n' \
        '<!doctype html>' \
        '<html lang="en">' \
        '  <head>' \
        '    <meta charset="utf-8">' \
        "    <meta http-equiv=\"refresh\" content=\"0; url=$destination\">" \
        "    <link rel=\"canonical\" href=\"$destination\">" \
        '    <title>Redirecting...</title>' \
        '  </head>' \
        '  <body>' \
        "    <p>Redirecting to <a href=\"$destination\">$destination</a>.</p>" \
        '  </body>' \
        '</html>' \
        > "out/$target"
    }

    makeRedirect index.xhtml index.html
    makeRedirect options.html options/home-manager/index.html
    makeRedirect options.xhtml options/home-manager/index.html
    makeRedirect nixos-options.xhtml options/nixos/index.html
    makeRedirect nix-darwin-options.xhtml options/nix-darwin/index.html
    makeRedirect release-notes.xhtml release-notes/release-notes.html

    runHook postBuild
  '';

  installPhase = ''
    dest="$out/${outputPath}"
    mkdir -p "$(dirname "$dest")"
    mv out "$dest"

    mkdir -p $out/nix-support/
    echo "doc manual $dest index.html" >> $out/nix-support/hydra-build-products
  '';

  passthru = {
    inherit home-manager-options mdbookOptions;
  };

  meta = {
    maintainers = [ lib.maintainers.considerate ];
  };
}
