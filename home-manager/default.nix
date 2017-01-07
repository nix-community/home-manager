{ pkgs }:

let

  homeManagerExpr = pkgs.writeText "home-manager.nix" ''
    { pkgs ? import <nixpkgs> {}, confPath, modulesPath }:

    let
      env = import modulesPath {
        configuration = import confPath;
        pkgs = pkgs;
      };
    in
      {
        inherit (env) activation-script;
      }
  '';

in

pkgs.stdenv.mkDerivation {
  name = "home-manager";

  phases = [ "installPhase" ];

  installPhase = ''
    install -v -D -m755 ${./home-manager} $out/bin/home-manager

    substituteInPlace $out/bin/home-manager \
      --subst-var-by bash "${pkgs.bash}" \
      --subst-var-by HOME_MANAGER_EXPR_PATH "${homeManagerExpr}"
  '';

  meta = with pkgs.stdenv.lib; {
    description = "A user environment configurator";
    maintainers = [ maintainers.rycee ];
    platforms = platforms.linux;
  };
}
