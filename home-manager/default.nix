{ lib, bash, callPackage, coreutils, findutils, gettext, gnused, inetutils
, installShellFiles, jq, less, ncurses, stdenvNoCC
# used for pkgs.path for nixos-option
, pkgs

# Path to use as the Home Manager channel.
, path ? null }:

let

  src = ../.;
  pathStr = if path == null then
    ""
  else if path == pkgs.path # `path` is not passed to `callPackage`
  then
    "${src}"
  else
    path;

  nixos-option = pkgs.nixos-option or (callPackage
    (pkgs.path + "/nixos/modules/installer/tools/nixos-option") { });

in stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "home-manager";
  name = finalAttrs.pname; # without `version`

  inherit src;
  preferLocalBuild = true;

  nativeBuildInputs = [ gettext installShellFiles ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -v -D -m755 home-manager/home-manager $out/bin/home-manager
    install -v -D -m755 lib/bash/home-manager.sh $out/share/bash/home-manager.sh

    installShellCompletion --cmd home-manager \
      --bash home-manager/completion.bash \
      --fish home-manager/completion.fish \
      --zsh home-manager/completion.zsh

    for pofile in home-manager/po/*.po; do
      lang="''${pofile##*/}"
      lang="''${lang%%.*}"
      mkdir -p "$out/share/locale/$lang/LC_MESSAGES"
      msgfmt -o "$out/share/locale/$lang/LC_MESSAGES/home-manager.mo" "$pofile"
    done

    runHook postInstall
  '';

  postFixup = ''
    substituteInPlace $out/bin/home-manager \
      --subst-var-by bash "${bash}" \
      --subst-var-by DEP_PATH "${
        lib.makeBinPath [
          coreutils
          findutils
          gettext
          gnused
          jq
          less
          ncurses
          nixos-option
          inetutils # for `hostname`
        ]
      }" \
      --subst-var-by HOME_MANAGER_LIB "$out/share/bash/home-manager.sh" \
      --subst-var-by HOME_MANAGER_PATH "${pathStr}" \
      --subst-var-by OUT "$out"
  '';

  meta = {
    homepage = "https://nix-community.github.io/home-manager/";
    description = "Nix-based user environment configurator";
    longDescription = ''
      The Home-Manager project provides a basic system for managing a user
      environment using the Nix package manager together with the Nix libraries
      found in Nixpkgs. It allows declarative configuration of user specific
      (non global) packages and dotfiles.
    '';
    license = lib.licenses.mit;
    mainProgram = "home-manager";
    maintainers = [ lib.maintainers.rycee ];
    platforms = lib.platforms.unix;
  };
})
