{ runCommand, lib, bash, callPackage, coreutils, findutils, gnused, less
# used for pkgs.path for nixos-option
, pkgs

# Extra path to Home Manager. If set then this path will be tried
# before `$HOME/.config/nixpkgs/home-manager` and
# `$HOME/.nixpkgs/home-manager`.
, path ? null }:

let

  pathStr = if path == null then "" else path;

  nixos-option = pkgs.nixos-option or (callPackage
    (pkgs.path + "/nixos/modules/installer/tools/nixos-option") { });

in runCommand "home-manager" {
  preferLocalBuild = true;
  meta = with lib; {
    description = "A user environment configurator";
    maintainers = [ maintainers.rycee ];
    platforms = platforms.unix;
    license = licenses.mit;
  };
} ''
  install -v -D -m755  ${./home-manager} $out/bin/home-manager

  substituteInPlace $out/bin/home-manager \
    --subst-var-by bash "${bash}" \
    --subst-var-by coreutils "${coreutils}" \
    --subst-var-by findutils "${findutils}" \
    --subst-var-by gnused "${gnused}" \
    --subst-var-by less "${less}" \
    --subst-var-by nixos-option "${nixos-option}" \
    --subst-var-by HOME_MANAGER_PATH '${pathStr}'

  install -D -m755 ${./completion.bash} \
    $out/share/bash-completion/completions/home-manager
  install -D -m755 ${./completion.zsh} \
    $out/share/zsh/site-functions/_home-manager
  install -D -m755 ${./completion.fish} \
    $out/share/fish/vendor_completions.d/home-manager.fish
''
