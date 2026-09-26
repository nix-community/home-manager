{ lib, realPkgs, ... }:
let
  expectWarnings = import ./warnings.nix { inherit lib; };
  # Option-default definitions merge with the option's own default, so the
  # warning names the module as well.
  optionDefaultFiles = [
    ../../../../modules/programs/borgmatic.nix
    ./legacy-defaults.nix
  ];
in
{
  programs.borgmatic = {
    enable = true;
    package = null;
    backups = {
      legacy.location = {
        sourceDirectories = [ "/source" ];
        repositories = [ { path = "/repo"; } ];
      };
      legacyNull = {
        location = {
          sourceDirectories = lib.mkForce null;
          patterns = [ "R /" ];
          repositories = [ "/repo" ];
        };
        retention.keepDaily = lib.mkForce null;
      };
      native.settings = {
        source_directories = [ "/source" ];
        repositories = [ { path = "/repo"; } ];
      };
      optionDefault = {
        location = {
          sourceDirectories = [ "/source" ];
          repositories = lib.mkOptionDefault [ "/repo" ];
        };
        consistency.checks = lib.mkOptionDefault [
          {
            name = "data";
            frequency = "always";
          }
        ];
      };
    };
  };

  test.asserts.warnings.expected =
    expectWarnings {
      file = ./legacy-defaults.nix;
      backup = "legacy";
      entries = [
        {
          from = "location.repositories";
          to = "settings.repositories";
          changed = true;
        }
        {
          from = "location.sourceDirectories";
          to = "settings.source_directories";
        }
      ];
    }
    ++ expectWarnings {
      file = ./legacy-defaults.nix;
      backup = "legacyNull";
      entries = [
        {
          from = "location.repositories";
          to = "settings.repositories";
          changed = true;
        }
        {
          from = "retention.keepDaily";
          to = "settings.keep_daily";
        }
        {
          from = "location.patterns";
          to = "settings.patterns";
        }
        {
          from = "location.sourceDirectories";
          to = "settings.source_directories";
        }
      ];
    }
    ++ expectWarnings {
      file = ./legacy-defaults.nix;
      backup = "optionDefault";
      entries = [
        {
          from = "consistency.checks";
          to = "settings.checks";
          changed = true;
          files = optionDefaultFiles;
        }
        {
          from = "location.repositories";
          to = "settings.repositories";
          changed = true;
          files = optionDefaultFiles;
        }
        {
          from = "location.sourceDirectories";
          to = "settings.source_directories";
        }
      ];
    };

  nmt.script = ''
    legacy=$TESTED/home-files/.config/borgmatic.d/legacy.yaml
    legacyNull=$TESTED/home-files/.config/borgmatic.d/legacyNull.yaml
    native=$TESTED/home-files/.config/borgmatic.d/native.yaml
    optionDefault=$TESTED/home-files/.config/borgmatic.d/optionDefault.yaml
    assertFileExists "$legacy"
    assertFileExists "$legacyNull"
    assertFileExists "$native"
    assertFileExists "$optionDefault"
    ${realPkgs.jq}/bin/jq --exit-status '
      .source_directories == ["/source"] and
      .repositories == [{"path": "/repo"}] and
      .checks == []
    ' "$legacy"
    ${realPkgs.jq}/bin/jq --exit-status '
      (has("source_directories") | not) and
      (has("keep_daily") | not) and
      .patterns == ["R /"]
    ' "$legacyNull"
    ${realPkgs.jq}/bin/jq --exit-status 'has("checks") | not' "$native"
    ${realPkgs.jq}/bin/jq --exit-status '
      .repositories == [{"path": "/repo"}] and
      .checks == [{"name": "data", "frequency": "always"}]
    ' "$optionDefault"
  '';
}
