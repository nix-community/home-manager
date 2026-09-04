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
    extraConfigFiles."linked/config.json".text = ''
      {"managed":true}
    '';
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script =
    let
      activationScript = pkgs.writeScript "obs-studio-containment-activation" config.home.activation.obsStudioConfig.data;
    in
    ''
      export HOME=$TMPDIR/hm-user

      configDir="$HOME/.config/obs-studio"
      outsideDir="$HOME/outside"
      outsideFile="$outsideDir/config.json"
      mkdir -p "$configDir/plugin_config" "$outsideDir"
      printf unmanaged > "$outsideFile"
      ln -s "$outsideDir" "$configDir/plugin_config/linked"

      sed "s|@TMPDIR@|$TMPDIR|g" ${activationScript} > $TMPDIR/activation-fragment
      {
        printf '%s\n' '#!${pkgs.runtimeShell}' 'run() { [[ "$1" == "--silence" ]] && shift; "$@"; }'
        cat $TMPDIR/activation-fragment
      } > $TMPDIR/activate
      chmod +x $TMPDIR/activate

      if $TMPDIR/activate; then
        fail "OBS Studio activation followed an intermediate symlink"
      fi
      assertFileContent "$outsideFile" ${builtins.toFile "obs-unmanaged-config" "unmanaged"}
    '';
}
