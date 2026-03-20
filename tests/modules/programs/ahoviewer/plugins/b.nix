{
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "plugin-b";
  version = "1.0.0";
  src = ./plugin-b;
  buildPhase = ''
    mkdir -p $out
    cp $src/* $out/
  '';
}
