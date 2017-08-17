{ pkgs

  # Extra path to the Home Manager modules. If set then this path will
  # be tried before `$HOME/.config/nixpkgs/home-manager/modules` and
  # `$HOME/.nixpkgs/home-manager/modules`.
, modulesPath ? null
}:

let

  homeManagerExpr = pkgs.writeText "home-manager.nix" ''
    { pkgs ? import <nixpkgs> {}, confPath, confAttr }:

    let
      env = import <home-manager> {
        configuration = let conf = import confPath;
                        in if (builtins.stringLength confAttr) == 0
                           then conf else conf.''${confAttr};
        pkgs = pkgs;
      };
    in
      {
        inherit (env) activation-script;
      }
  '';

  modulesPathStr = if modulesPath == null then "" else modulesPath;

in

pkgs.stdenv.mkDerivation {
  name = "home-manager";

  phases = [ "installPhase" ];

  installPhase = ''
    install -v -D -m755 ${./home-manager} $out/bin/home-manager

    substituteInPlace $out/bin/home-manager \
      --subst-var-by bash "${pkgs.bash}" \
      --subst-var-by coreutils "${pkgs.coreutils}" \
      --subst-var-by MODULES_PATH '${modulesPathStr}' \
      --subst-var-by HOME_MANAGER_EXPR_PATH "${homeManagerExpr}"
  '';

  meta = with pkgs.stdenv.lib; {
    description = "A user environment configurator";
    maintainers = [ maintainers.rycee ];
    platforms = platforms.linux;
  };
}
