{ pkgs ? (import <nixpkgs> { }), }:

pkgs.stdenv.mkDerivation {
  name = "podmactl";
  src = ./.;

  buildInputs = [ pkgs.python311 ];
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    (
        cd $src
        black --check .
        python -m unittest
    )
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp podmactl.py $out/bin/podmactl
    chmod +x $out/bin/podmactl

    runHook postInstall
  '';
}
