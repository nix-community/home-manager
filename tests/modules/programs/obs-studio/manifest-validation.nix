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
      activationScript = pkgs.writeScript "obs-studio-manifest-validation" config.home.activation.obsStudioConfig.data;
    in
    ''
      export HOME=$TMPDIR/hm-user

      configDir="$HOME/.config/obs-studio"
      manifestFile="$HOME/.local/state/home-manager/obs-studio/manifest.json"
      managedFile="$configDir/global.ini"
      outsideFile="$HOME/outside.txt"
      mkdir -p "$configDir" "$(dirname "$manifestFile")"
      printf managed > "$managedFile"
      printf outside > "$outsideFile"
      ${pkgs.jq}/bin/jq -n \
        '{
          version: 1,
          module: "programs.obs-studio",
          files: [{ path: ("global.ini" + "\u0000" + "../outside.txt") }]
        }' > "$manifestFile"

      sed "s|@TMPDIR@|$TMPDIR|g" ${activationScript} > $TMPDIR/activation-fragment
      {
        printf '%s\n' '#!${pkgs.runtimeShell}' 'run() { [[ "$1" == "--silence" ]] && shift; "$@"; }'
        cat $TMPDIR/activation-fragment
      } > $TMPDIR/activate
      chmod +x $TMPDIR/activate

      if $TMPDIR/activate; then
        fail "OBS Studio activation accepted a NUL-containing manifest path"
      fi
      assertFileContent "$managedFile" ${builtins.toFile "obs-managed" "managed"}
      assertFileContent "$outsideFile" ${builtins.toFile "obs-outside" "outside"}
    '';
}
