{ pkgs, lib, ... }:
let
  product_json = builtins.toJSON {
    nameShort = "Code";
    dataFolderName = ".vscode";
  };

in
pkgs.stdenvNoCC.mkDerivation {
  name = "fake-vscode";
  version = "1.75.0";

  meta.mainProgram = "code";

  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin/
    touch $out/bin/code;
    chmod +x $out/bin/code;

    mkdir -p $out/lib/vscode/resources/app/
    cat << EOF > $out/lib/vscode/resources/app/product.json
    ${product_json}
    EOF
  '';
}
