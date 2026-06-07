{ pkgs, ... }:
let
  filter = pkgs.writeText "openclaw-settings-merge.jq" (
    import ../../../../modules/services/openclaw/settings-merge.nix
  );
in
{
  nmt.script = ''
    set -euo pipefail

    jq_bin=${pkgs.jq}/bin/jq
    filter=${filter}
    tmpdir=$(mktemp -d "''${TMPDIR:-/tmp}/openclaw-settings-merge-test.XXXXXX")
    trap 'rm -rf "$tmpdir"' EXIT

    case_no=0

    assert_case() {
      local name=$1
      local live=$2
      local declared=$3
      local expected=$4
      local actual=$tmpdir/$case_no-actual.json

      "$jq_bin" -s -f "$filter" "$live" "$declared" >"$actual"
      "$jq_bin" -S . "$expected" >"$tmpdir/$case_no-expected.sorted.json"
      "$jq_bin" -S . "$actual" >"$tmpdir/$case_no-actual.sorted.json"
      if ! diff -u "$tmpdir/$case_no-expected.sorted.json" "$tmpdir/$case_no-actual.sorted.json"; then
        echo "settings merge case failed: $name" >&2
        exit 1
      fi
    }

    next_case() {
      case_no=$((case_no + 1))
      case_dir=$tmpdir/case-$case_no
      mkdir -p "$case_dir"
    }

    next_case
    cat >"$case_dir/live.json" <<'EOF'
    {
      "gateway": {
        "port": 19999,
        "runtimeOnly": true,
        "nested": {
          "runtime": "keep",
          "override": "runtime"
        }
      },
      "session": {
        "idleMinutes": 12345
      },
      "scalar": "runtime"
    }
    EOF
    cat >"$case_dir/declared.json" <<'EOF'
    {
      "gateway": {
        "port": 18789,
        "bind": "loopback",
        "nested": {
          "override": "declared",
          "declared": "add"
        }
      },
      "scalar": "declared"
    }
    EOF
    cat >"$case_dir/expected.json" <<'EOF'
    {
      "gateway": {
        "port": 18789,
        "runtimeOnly": true,
        "bind": "loopback",
        "nested": {
          "runtime": "keep",
          "override": "declared",
          "declared": "add"
        }
      },
      "session": {
        "idleMinutes": 12345
      },
      "scalar": "declared"
    }
    EOF
    assert_case "recursive objects and scalar override" "$case_dir/live.json" "$case_dir/declared.json" "$case_dir/expected.json"

    next_case
    cat >"$case_dir/live.json" <<'EOF'
    {
      "plugins": {
        "enabled": [
          "runtime-only",
          "declared-existing"
        ]
      },
      "agents": {
        "list": [
          {
            "id": "runtime-agent"
          },
          {
            "id": "declared-agent"
          }
        ]
      }
    }
    EOF
    cat >"$case_dir/declared.json" <<'EOF'
    {
      "plugins": {
        "enabled": [
          "declared-existing",
          "declared-new"
        ]
      },
      "agents": {
        "list": [
          {
            "id": "declared-agent"
          }
        ]
      }
    }
    EOF
    cat >"$case_dir/expected.json" <<'EOF'
    {
      "plugins": {
        "enabled": [
          "declared-existing",
          "declared-new",
          "runtime-only"
        ]
      },
      "agents": {
        "list": [
          {
            "id": "declared-agent"
          },
          {
            "id": "runtime-agent"
          }
        ]
      }
    }
    EOF
    assert_case "declared-first arrays preserve runtime additions" "$case_dir/live.json" "$case_dir/declared.json" "$case_dir/expected.json"

    next_case
    cat >"$case_dir/live.json" <<'EOF'
    {
      "agents": {
        "list": [
          {
            "id": "main",
            "default": true,
            "runtime": {
              "lastSession": "keep"
            },
            "skills": ["old"],
            "theme": "runtime"
          },
          {
            "id": "runtime-agent",
            "default": false
          }
        ]
      }
    }
    EOF
    cat >"$case_dir/declared.json" <<'EOF'
    {
      "agents": {
        "list": [
          {
            "id": "main",
            "default": true,
            "model": "declared",
            "skills": ["new"],
            "theme": "declared"
          }
        ]
      }
    }
    EOF
    cat >"$case_dir/expected.json" <<'EOF'
    {
      "agents": {
        "list": [
          {
            "id": "main",
            "default": true,
            "model": "declared",
            "runtime": {
              "lastSession": "keep"
            },
            "skills": ["new", "old"],
            "theme": "declared"
          },
          {
            "id": "runtime-agent",
            "default": false
          }
        ]
      }
    }
    EOF
    assert_case "object arrays with id merge matching objects and append runtime objects" "$case_dir/live.json" "$case_dir/declared.json" "$case_dir/expected.json"

    next_case
    cat >"$case_dir/live.json" <<'EOF'
    {
      "gateway": {
        "port": 19999
      },
      "tools": [
        "runtime"
      ]
    }
    EOF
    cat >"$case_dir/declared.json" <<'EOF'
    {
      "gateway": false,
      "tools": {
        "profile": "declared"
      }
    }
    EOF
    cat >"$case_dir/expected.json" <<'EOF'
    {
      "gateway": false,
      "tools": {
        "profile": "declared"
      }
    }
    EOF
    assert_case "declared type replaces runtime type" "$case_dir/live.json" "$case_dir/declared.json" "$case_dir/expected.json"
  '';
}
