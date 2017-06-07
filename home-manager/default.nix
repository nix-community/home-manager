{ pkgs, modulesPath ? "$HOME/.config/nixpkgs/home-manager/modules" }:

let

  homeManagerExpr = pkgs.writeText "home-manager.nix" ''
    { pkgs ? import <nixpkgs> {}, confPath }:

    let
      env = import <home-manager> {
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
      --subst-var-by coreutils "${pkgs.coreutils}" \
      --subst-var-by MODULES_PATH '${modulesPath}' \
      --subst-var-by HOME_MANAGER_EXPR_PATH "${homeManagerExpr}"
  '';

  meta = with pkgs.stdenv.lib; {
    description = "A user environment configurator";
    maintainers = [ maintainers.rycee ];
    platforms = platforms.linux;
  };
}
