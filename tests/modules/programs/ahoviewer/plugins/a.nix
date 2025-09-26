{
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "plugin-a";
  version = "1.0.0";
  src = ./plugin-a;
  buildPhase = ''
    mkdir -p $out
    cp $src/* $out/
  '';
}
