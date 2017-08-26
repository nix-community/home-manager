{ pkgs

  # Extra path to the Home Manager modules. If set then this path will
  # be tried before `$HOME/.config/nixpkgs/home-manager/modules` and
  # `$HOME/.nixpkgs/home-manager/modules`.
, modulesPath ? null
}:

let

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
      --subst-var-by less "${pkgs.less}" \
      --subst-var-by MODULES_PATH '${modulesPathStr}' \
      --subst-var-by HOME_MANAGER_EXPR_PATH "${./home-manager.nix}"
  '';

  meta = with pkgs.stdenv.lib; {
    description = "A user environment configurator";
    maintainers = [ maintainers.rycee ];
    platforms = platforms.linux;
  };
}
