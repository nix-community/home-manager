{ stdenv, lib, documentation-highlighter, revision, home-manager-options
, nixos-render-docs }:
let outputPath = "share/doc/home-manager";
in stdenv.mkDerivation {
  name = "home-manager-manual";

  nativeBuildInputs = [ nixos-render-docs ];

  src = ./manual;

  buildPhase = ''
    mkdir -p out/{highlightjs,media}

    cp -t out/highlightjs \
      ${documentation-highlighter}/highlight.pack.js \
      ${documentation-highlighter}/LICENSE \
      ${documentation-highlighter}/mono-blue.css \
      ${documentation-highlighter}/loader.js

    substituteInPlace ./options.md \
      --subst-var-by \
        OPTIONS_JSON \
        ${home-manager-options.home-manager}/share/doc/nixos/options.json

    substituteInPlace ./nixos-options.md \
      --subst-var-by \
        OPTIONS_JSON \
        ${home-manager-options.nixos}/share/doc/nixos/options.json

    substituteInPlace ./nix-darwin-options.md \
      --subst-var-by \
        OPTIONS_JSON \
        ${home-manager-options.nix-darwin}/share/doc/nixos/options.json

    cp ${./static/style.css} out/style.css

    cp -r ${./release-notes} release-notes

    nixos-render-docs manual html \
      --manpage-urls ./manpage-urls.json \
      --revision ${lib.trivial.revisionWithDefault revision} \
      --stylesheet style.css \
      --script highlightjs/highlight.pack.js \
      --script highlightjs/loader.js \
      --toc-depth 1 \
      --section-toc-depth 1 \
      manual.md \
      out/index.xhtml
  '';

  installPhase = ''
    dest="$out/${outputPath}"
    mkdir -p "$(dirname "$dest")"
    mv out "$dest"

    mkdir -p $out/nix-support/
    echo "doc manual $dest index.html" >> $out/nix-support/hydra-build-products
  '';

  meta = { maintainers = [ lib.maintainers.considerate ]; };
}
