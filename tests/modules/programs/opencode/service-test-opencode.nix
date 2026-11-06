{ pkgs }:

pkgs.runCommand "opencode-2.1.1"
  {
    version = "2.1.1";
    meta.mainProgram = "opencode";
  }
  ''
    mkdir -p $out/bin
    cat > $out/bin/opencode <<'EOF'
    #!/bin/sh
    set -eu

    printf '%s\n' "$*" >> "$OPENCODE_TEST_LOG"
    case "$*" in
      "service status")
        if [ -f "$OPENCODE_TEST_STATUS" ]; then
          cat "$OPENCODE_TEST_STATUS"
        else
          printf 'stopped\n'
        fi
        ;;
      "service stop")
        printf 'stopped\n' > "$OPENCODE_TEST_STATUS"
        ;;
      "service restart")
        printf 'http://127.0.0.1:4096\n' > "$OPENCODE_TEST_STATUS"
        ;;
      *)
        printf 'unexpected arguments: %s\n' "$*" >&2
        exit 1
        ;;
    esac
    EOF
    chmod +x $out/bin/opencode
  ''
