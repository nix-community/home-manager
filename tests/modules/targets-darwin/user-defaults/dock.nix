{ pkgs, ... }:
{
  config = {
    targets.darwin.defaults."com.apple.dock" = {
      persistent-apps = [
        "/Applications/Calendar.app"
        /.
        { app = "/Applications/Mail.app"; }
        { file = "/Users/test/notes.txt"; }
        { folder = "/Users/test/Documents"; }
        { spacer = { }; }
        { spacer.small = false; }
        { spacer.small = true; }
        {
          app = "metadata-that-must-not-be-reinterpreted";
          tile-data.arbitrary-native-key = "preserved";
          tile-type = "arbitrary-native-tile";
        }
        { }
      ];
      persistent-others = [
        "/Users/test/Downloads"
        { folder.path = "/Users/test/Desktop"; }
        { folder = "/Users/test/Documents"; }
        /.
        {
          folder = {
            path = "/Users/test/Projects";
            arrangement = "date-modified";
            displayas = "folder";
            showas = "list";
          };
        }
        { file = "/Users/test/archive.zip"; }
        {
          arbitrary-native-key = "preserved";
          folder = "metadata-that-must-not-be-reinterpreted";
          tile-data.file-data = {
            _CFURLString = "file:///Users/test/native";
            _CFURLStringType = 15;
          };
          tile-type = "directory-tile";
        }
      ];
    };

    nmt.script = ''
      plist=$(grep -oE '/nix/store/[a-z0-9]+-com[.]apple[.]dock[.]plist' "$TESTED/activate")
      test -n "$plist"
      ${pkgs.python3}/bin/python - "$plist" <<'PY'
      import plistlib
      import sys

      with open(sys.argv[1], "rb") as stream:
          plist = plistlib.load(stream)

      assert plist["persistent-apps"] == [
          {"tile-data": {"file-data": {
              "_CFURLString": "/Applications/Calendar.app", "_CFURLStringType": 0,
          }}},
          {"tile-data": {"file-data": {
              "_CFURLString": "/", "_CFURLStringType": 0,
          }}},
          {"tile-data": {"file-data": {
              "_CFURLString": "/Applications/Mail.app", "_CFURLStringType": 0,
          }}},
          {"tile-data": {"file-data": {
              "_CFURLString": "file:///Users/test/notes.txt", "_CFURLStringType": 15,
          }}, "tile-type": "file-tile"},
          {"tile-data": {"file-data": {
              "_CFURLString": "file:///Users/test/Documents", "_CFURLStringType": 15,
          }}, "tile-type": "directory-tile"},
          {"tile-data": {}, "tile-type": "spacer-tile"},
          {"tile-data": {}, "tile-type": "spacer-tile"},
          {"tile-data": {}, "tile-type": "small-spacer-tile"},
          {"app": "metadata-that-must-not-be-reinterpreted",
           "tile-data": {"arbitrary-native-key": "preserved"},
           "tile-type": "arbitrary-native-tile"},
          {},
      ]
      assert plist["persistent-others"] == [
          {"tile-data": {"file-data": {
              "_CFURLString": "file:///Users/test/Downloads", "_CFURLStringType": 15,
          }, "arrangement": 1, "displayas": 0, "showas": 0}, "tile-type": "directory-tile"},
          {"tile-data": {"file-data": {
              "_CFURLString": "file:///Users/test/Desktop", "_CFURLStringType": 15,
          }, "arrangement": 1, "displayas": 0, "showas": 0}, "tile-type": "directory-tile"},
          {"tile-data": {"file-data": {
              "_CFURLString": "file:///Users/test/Documents", "_CFURLStringType": 15,
          }, "arrangement": 1, "displayas": 0, "showas": 0}, "tile-type": "directory-tile"},
          {"tile-data": {"file-data": {
              "_CFURLString": "file:///", "_CFURLStringType": 15,
          }, "arrangement": 1, "displayas": 0, "showas": 0}, "tile-type": "directory-tile"},
          {"tile-data": {"file-data": {
              "_CFURLString": "file:///Users/test/Projects", "_CFURLStringType": 15,
          }, "arrangement": 3, "displayas": 1, "showas": 3}, "tile-type": "directory-tile"},
          {"tile-data": {"file-data": {
              "_CFURLString": "file:///Users/test/archive.zip", "_CFURLStringType": 15,
          }}, "tile-type": "file-tile"},
          {"arbitrary-native-key": "preserved",
           "folder": "metadata-that-must-not-be-reinterpreted",
           "tile-data": {"file-data": {
              "_CFURLString": "file:///Users/test/native", "_CFURLStringType": 15,
          }}, "tile-type": "directory-tile"},
      ]
      PY
    '';
  };
}
