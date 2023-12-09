{ writeShellScriptBin, makeDesktopItem, symlinkJoin }:
{ html, pathName ? "home-manager", projectName ? pathName
, name ? "${pathName}-help" }:
let
  helpScript = writeShellScriptBin name ''
    set -euo pipefail

    if [[ ! -v BROWSER || -z $BROWSER ]]; then
      for candidate in xdg-open open w3m; do
        BROWSER="$(type -P $candidate || true)"
        if [[ -x $BROWSER ]]; then
          break;
        fi
      done
    fi

    if [[ ! -v BROWSER || -z $BROWSER ]]; then
      echo "$0: unable to start a web browser; please set \$BROWSER"
      exit 1
    else
      exec "$BROWSER" "${html}/share/doc/${pathName}/index.xhtml"
    fi
  '';

  desktopItem = makeDesktopItem {
    name = "${pathName}-manual";
    desktopName = "${projectName} Manual";
    genericName = "View ${projectName} documentation in a web browser";
    icon = "nix-snowflake";
    exec = "${helpScript}/bin/${name}";
    categories = [ "System" ];
  };
in symlinkJoin {
  inherit name;
  paths = [ helpScript desktopItem ];
}
