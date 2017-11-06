{ pkgs

  # Extra path to Home Manager. If set then this path will be tried
  # before `$HOME/.config/nixpkgs/home-manager` and
  # `$HOME/.nixpkgs/home-manager`.
, path ? null
}:

let

  pathStr = if path == null then "" else path;

in

pkgs.stdenv.mkDerivation {
  name = "home-manager";

  buildCommand = ''
    install -v -D -m755 ${./home-manager} $out/bin/home-manager

    substituteInPlace $out/bin/home-manager \
      --subst-var-by bash "${pkgs.bash}" \
      --subst-var-by coreutils "${pkgs.coreutils}" \
      --subst-var-by less "${pkgs.less}" \
      --subst-var-by HOME_MANAGER_PATH '${pathStr}'
  '';

  meta = with pkgs.stdenv.lib; {
    description = "A user environment configurator";
    maintainers = [ maintainers.rycee ];
    platforms = platforms.unix;
    license = licenses.mit;
  };
}
