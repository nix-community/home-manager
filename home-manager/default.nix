{ runCommand, lib, bash, coreutils, findutils, gettext, gnused, less, ncurses
, unixtools
# used for pkgs.path for nixos-option
, pkgsPath
# Path to use as the Home Manager channel.
, path ? null
  # Do we need this anymore??
, callPackage, nixos-option ?
  (callPackage "${pkgsPath}/nixos/modules/installer/tools/nixos-option" { }) }:

let

  pathStr = if path == null then "" else path;

in runCommand "home-manager" {
  preferLocalBuild = true;
  nativeBuildInputs = [ gettext ];
  meta = with lib; {
    mainProgram = "home-manager";
    description = "A user environment configurator";
    maintainers = [ maintainers.rycee ];
    platforms = platforms.unix;
    license = licenses.mit;
  };
} ''
  install -v -D -m755  ${./home-manager} $out/bin/home-manager

  substituteInPlace $out/bin/home-manager \
    --subst-var-by bash "${bash}" \
    --subst-var-by DEP_PATH "${
      lib.makeBinPath [
        coreutils
        findutils
        gettext
        gnused
        less
        ncurses
        nixos-option
        unixtools.hostname
      ]
    }" \
    --subst-var-by HOME_MANAGER_LIB '${../lib/bash/home-manager.sh}' \
    --subst-var-by HOME_MANAGER_PATH '${pathStr}' \
    --subst-var-by OUT "$out" \
    --subst-var-by pkgsPath '${pkgsPath}'

  install -D -m755 ${./completion.bash} \
    $out/share/bash-completion/completions/home-manager
  install -D -m755 ${./completion.zsh} \
    $out/share/zsh/site-functions/_home-manager
  install -D -m755 ${./completion.fish} \
    $out/share/fish/vendor_completions.d/home-manager.fish

  install -D -m755 ${../lib/bash/home-manager.sh} \
    "$out/share/bash/home-manager.sh"

  for path in ${./po}/*.po; do
    lang="''${path##*/}"
    lang="''${lang%%.*}"
    mkdir -p "$out/share/locale/$lang/LC_MESSAGES"
    msgfmt -o "$out/share/locale/$lang/LC_MESSAGES/home-manager.mo" "$path"
  done
''
