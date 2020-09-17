{ config, lib, pkgs, ... }:

with lib;

let
  desktopFileExample = pkgs.stdenv.mkDerivation {
    name = "desktop-file-example";
    buildCommand = ''
      mkdir -p $out/share/applications
      cp ${./example.desktop} $out/share/applications/example.desktop
    '';
  };
  mimeTypeExample = pkgs.stdenv.mkDerivation {
    name = "mime-type-example";
    buildCommand = ''
      mkdir -p $out/share/mime/packages
      cp ${./example.xml} $out/share/mime/packages/example.xml
    '';
  };

in {
  config = {
    xdg = {
      enable = true;
      mime.enable = true;
    };
    home.packages = [ desktopFileExample mimeTypeExample ];

    nmt.script = ''
      assertFileExists home-path/share/applications/example.desktop
      assertFileContent \
        home-path/share/applications/example.desktop \
        ${./example.desktop}

      assertFileExists home-path/share/mime/packages/example.xml
      assertFileContent \
        home-path/share/mime/packages/example.xml \
        ${./example.xml}

      ${pkgs.xdg_utils}/bin/xdg-mime query default application/example > $out/query-output.txt
      assertFileContent $out/output.txt ${./query-output.txt}

      ${pkgs.xdg_utils}/bin/xdg-open ${./example.xyz} > $out/output.txt
      assertFileContent $out/output.txt ${./example.xyz}
    '';
  };
}
