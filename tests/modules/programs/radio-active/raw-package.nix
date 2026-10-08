{ pkgs, ... }:

{
  programs.radio-active = {
    enable = true;
    package = builtins.derivation {
      name = "radio-active-raw";
      system = pkgs.stdenv.hostPlatform.system;
      builder = "${pkgs.runtimeShell}";
      args = [
        "-c"
        ''
          ${pkgs.coreutils}/bin/mkdir -p "$out/bin"
          ${pkgs.coreutils}/bin/cat > "$out/bin/radio" <<'EOF'
          #!${pkgs.runtimeShell}
          player="$(command -v mpv)"
          printf '%s\n' "$player"
          exec "$player"
          EOF
          ${pkgs.coreutils}/bin/chmod +x "$out/bin/radio"
          ${pkgs.coreutils}/bin/ln -s radio "$out/bin/radioactive"
        ''
      ];
    };
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
    assertFileExists home-path/bin/radio
    assertFileExists home-path/bin/radioactive

    ambientDir=$(mktemp -d)
    trap 'rm -rf "$ambientDir"' EXIT
    cat > "$ambientDir/mpv" <<'EOF'
    #!${pkgs.runtimeShell}
    printf 'ambient-mpv\n'
    EOF
    chmod +x "$ambientDir/mpv"
    expected="${pkgs.mpv}/bin/mpv
    selected-mpv"
    test "$(PATH="$ambientDir" "$TESTED/home-path/bin/radio")" = "$expected"
    test "$(PATH="$ambientDir" "$TESTED/home-path/bin/radioactive")" = "$expected"
  '';
}
