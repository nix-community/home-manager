{ pkgs, ... }:

{
  programs.radio-active = {
    enable = true;

    package = pkgs.writeShellScriptBin "radio-active-custom" ''
      set -eu
      player="$(command -v mpv)"
      helper="$(command -v radio-helper)"
      printf '%s\n%s\n' "$player" "$helper"
      exec "$player"
    '';

    settings.AppConfig.player = "mpv";
  };

  test.stubs.mpv = {
    outPath = null;
    buildScript = ''
      mkdir -p "$out/bin"
      cat > "$out/bin/mpv" <<'EOF'
      #!${pkgs.runtimeShell}
      printf 'selected-mpv\n'
      EOF
      chmod +x "$out/bin/mpv"
    '';
  };

  nmt.script = ''
    set -eu
    assertFileExists home-path/bin/radio-active-custom

    ambientDir=$(mktemp -d)
    trap 'rm -rf "$ambientDir"' EXIT
    cat > "$ambientDir/mpv" <<'EOF'
    #!${pkgs.runtimeShell}
    printf 'ambient-mpv\n'
    EOF
    cat > "$ambientDir/radio-helper" <<'EOF'
    #!${pkgs.runtimeShell}
    :
    EOF
    chmod +x "$ambientDir/mpv" "$ambientDir/radio-helper"
    output=$(PATH="$ambientDir" "$TESTED/home-path/bin/radio-active-custom")
    expected="${pkgs.mpv}/bin/mpv
    $ambientDir/radio-helper
    selected-mpv"
    test "$output" = "$expected"

    assertFileExists home-files/.config/radio-active/configs.ini
    assertFileContent home-files/.config/radio-active/configs.ini \
    ${builtins.toFile "expected.player_mpv.radio-active_configs.ini" ''
      [AppConfig]
      player=mpv
    ''}
  '';
}
