{ pkgs, ... }:

{
  programs.radio-active = {
    enable = true;

    package = pkgs.writeShellScriptBin "radio-active-custom" ''
      set -eu
      player="$(command -v vlc)"
      helper="$(command -v radio-helper)"
      printf '%s\n%s\n' "$player" "$helper"
      exec "$player"
    '';

    settings.AppConfig.player = "vlc";
  };

  test.stubs.vlc = {
    outPath = null;
    buildScript = ''
      mkdir -p "$out/bin"
      cat > "$out/bin/vlc" <<'EOF'
      #!${pkgs.runtimeShell}
      printf 'selected-vlc\n'
      EOF
      chmod +x "$out/bin/vlc"
    '';
  };

  nmt.script = ''
    set -eu
    assertFileExists home-path/bin/radio-active-custom

    ambientDir=$(mktemp -d)
    trap 'rm -rf "$ambientDir"' EXIT
    cat > "$ambientDir/vlc" <<'EOF'
    #!${pkgs.runtimeShell}
    printf 'ambient-vlc\n'
    EOF
    cat > "$ambientDir/radio-helper" <<'EOF'
    #!${pkgs.runtimeShell}
    :
    EOF
    chmod +x "$ambientDir/vlc" "$ambientDir/radio-helper"
    output=$(PATH="$ambientDir" "$TESTED/home-path/bin/radio-active-custom")
    expected="${pkgs.vlc}/bin/vlc
    $ambientDir/radio-helper
    selected-vlc"
    test "$output" = "$expected"

    assertFileExists home-files/.config/radio-active/configs.ini
    assertFileContent home-files/.config/radio-active/configs.ini \
    ${builtins.toFile "expected.player_vlc.radio-active_configs.ini" ''
      [AppConfig]
      player=vlc
    ''}
  '';
}
