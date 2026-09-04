{
  config,
  lib,
  pkgs,
  ...
}:
let
  obsPackage = pkgs.runCommand "obs" { passthru = { }; } ''
    mkdir -p $out/bin $out/share/obs/obs-plugins
    printf '#!${pkgs.runtimeShell}\n' > $out/bin/obs
    chmod +x $out/bin/obs
  '';
in
{
  programs.obs-studio = {
    enable = true;
    package = obsPackage;
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script =
    let
      activationScript = pkgs.writeScript "obs-studio-cleanup-activation" config.home.activation.obsStudioConfig.data;
    in
    ''
      export HOME=$TMPDIR/hm-user

      configDir="$HOME/.config/obs-studio"
      manifestFile="$HOME/.local/state/home-manager/obs-studio/manifest.json"
      managedFile="$configDir/global.ini"
      linkedFile="$configDir/basic/scenes/Linked.json"
      unmanagedFile="$configDir/basic/scenes/Untitled.json"
      outsideFile="$HOME/outside.txt"
      outsideDir="$HOME/outside"
      escapedFile="$outsideDir/Escape.json"
      outsideEmptyDir="$outsideDir/empty"
      linkedDir="$configDir/plugin_config/linked"

      mkdir -p \
        "$(dirname "$linkedFile")" \
        "$(dirname "$manifestFile")" \
        "$outsideEmptyDir" \
        "$(dirname "$linkedDir")"
      printf managed > "$managedFile"
      printf unmanaged > "$unmanagedFile"
      printf outside > "$outsideFile"
      printf escaped > "$escapedFile"
      ln -s "$outsideFile" "$linkedFile"
      ln -s "$outsideDir" "$linkedDir"
      ${pkgs.jq}/bin/jq -n \
        --arg managed "$managedFile" \
        --arg linked "$linkedFile" \
        --arg outside "$outsideFile" \
        --arg escaped "$escapedFile" \
        --arg escapedMissing "$outsideEmptyDir/missing.json" \
        '{
          version: 1,
          module: "programs.obs-studio",
          files: [
            { path: "global.ini", target: $managed },
            { path: "basic/scenes/Linked.json", target: $linked },
            { path: "../outside.txt", target: $outside },
            { path: "plugin_config/linked/Escape.json", target: $escaped },
            { path: "plugin_config/linked/empty/missing.json", target: $escapedMissing }
          ]
        }' > "$manifestFile"

      sed "s|@TMPDIR@|$TMPDIR|g" ${activationScript} > $TMPDIR/activate
      run() {
        [[ "$1" == "--silence" ]] && shift
        "$@"
      }
      . $TMPDIR/activate

      assertPathNotExists "$managedFile"
      assertPathNotExists "$linkedFile"
      assertFileContent "$unmanagedFile" ${builtins.toFile "obs-unmanaged" "unmanaged"}
      assertFileContent "$outsideFile" ${builtins.toFile "obs-outside" "outside"}
      assertFileContent "$escapedFile" ${builtins.toFile "obs-escaped" "escaped"}
      test -d "$outsideEmptyDir"
      ${pkgs.jq}/bin/jq -e '.files == []' "$manifestFile" >/dev/null
    '';
}
