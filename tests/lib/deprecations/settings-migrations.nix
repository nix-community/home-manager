{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  cases = [
    "mixed"
    "forced"
    "weak"
    "empty"
    "canonicalForce"
    "unset"
  ];
  overlays = lib.genAttrs cases (
    name:
    lib.hm.deprecations.mkSettingsOverlay {
      inherit options;
      from = [
        "test"
        "overlays"
        name
        "old"
      ];
      to = [
        "test"
        "overlays"
        name
        "settings"
      ];
    }
  );
in
{
  imports = map (name: overlays.${name}.module) cases ++ [
    {
      _file = "overlay-first.nix";
      config.test.overlays.mixed.old = lib.mkDefault { provenanceA = 1; };
    }
    {
      _file = "overlay-second.nix";
      config.test.overlays.mixed.old = lib.mkDefault { provenanceB = 2; };
    }
  ];
  options.test.overlays = lib.genAttrs cases (_: {
    settings = lib.mkOption {
      type = lib.types.attrsOf (pkgs.formats.json { }).type;
      default = { };
    };
  });
  config = {
    test.asserts.warnings.expected =
      map
        (
          name:
          "The option `test.overlays.${name}.old' defined in ${
            lib.showFiles options.test.overlays.${name}.old.files
          } has been renamed to `test.overlays.${name}.settings'."
        )
        [
          "canonicalForce"
          "empty"
          "forced"
          "mixed"
        ];
    test.overlays = {
      mixed = {
        old = lib.mkDefault {
          "literal.key" = 7;
          defined = lib.mkDefinition {
            file = "legacy-key.nix";
            value = lib.mkForce "legacy";
          };
          absent = lib.mkIf false (throw "disabled content was forced");
          conditional = lib.mkIf true (lib.mkDefault "old");
          nested = {
            value = lib.mkDefault "old";
            list = lib.mkAfter [ "last" ];
          };
          first = lib.mkBefore [ "first" ];
          nullValue = null;
          emptyString = "";
          falseValue = false;
          zero = 0;
          emptyList = [ ];
          emptyAttrs = { };
          lazy = {
            value = throw "presence check forced nested content";
          };
        };
        settings = {
          defined = "canonical";
          conditional = "new";
          nested = lib.mkDefault {
            value = "new";
            list = [ "first" ];
          };
          first = lib.mkDefault [ "last" ];
          unrelated = "keep";
        };
      };
      forced = {
        old = lib.mkForce {
          value = "forced";
          conditional = lib.mkMerge [
            (lib.mkIf false (throw "disabled merge branch was forced"))
            (lib.mkIf true (lib.mkDefault "old"))
          ];
        };
        settings = {
          value = "ordinary";
          conditional = "new";
          unrelated = true;
        };
      };
      weak.old = lib.mkOverride 1501 { value = lib.mkForce "ignored"; };
      empty.old = { };
      canonicalForce = {
        old.value = "legacy";
        settings = lib.mkForce { canonical = true; };
      };
    };
    assertions = [
      {
        assertion =
          let
            withoutWarnings = lib.evalModules {
              modules = [
                ({ options, ... }: {
                  imports =
                    (lib.hm.deprecations.mkSettingsRenamedOptionModules [ ] [ "settings" ] {
                      preserveOrder = true;
                    } [ "items" ])
                    ++ [
                      (lib.hm.deprecations.mkSettingsOverlay {
                        inherit options;
                        from = [ "old" ];
                        to = [ "overlaySettings" ];
                      }).module
                    ];
                  options = {
                    settings.items = lib.mkOption { type = lib.types.listOf lib.types.str; };
                    overlaySettings = lib.mkOption {
                      type = lib.types.attrsOf (pkgs.formats.json { }).type;
                      default = { };
                    };
                  };
                })
                {
                  items = lib.mkBefore [ "legacy" ];
                  settings.items = [ "canonical" ];
                  old.value = 1;
                }
                { items = lib.mkAfter [ "legacy-after" ]; }
              ];
            };
          in
          withoutWarnings.config.settings.items == [
            "legacy"
            "canonical"
            "legacy-after"
          ]
          && withoutWarnings.config.overlaySettings.value == 1;
        message = "Settings migrations must work without a warnings option.";
      }
      {
        assertion =
          overlays.mixed.keys == [
            "conditional"
            "defined"
            "emptyAttrs"
            "emptyList"
            "emptyString"
            "falseValue"
            "first"
            "lazy"
            "literal.key"
            "nested"
            "nullValue"
            "provenanceA"
            "provenanceB"
            "zero"
          ];
        message = "Overlay keys must exclude absent conditions without forcing nested values.";
      }
      {
        assertion =
          let
            settings = config.test.overlays.mixed.settings;
          in
          settings.provenanceA == 1
          && settings.provenanceB == 2
          && settings.defined == "legacy"
          && settings."literal.key" == 7
          && !(settings ? literal)
          && !(settings ? absent)
          && settings.conditional == "new"
          && settings.unrelated == "keep"
          &&
            settings.nested == {
              value = "new";
              list = [
                "first"
                "last"
              ];
            }
          &&
            settings.first == [
              "first"
              "last"
            ]
          && settings.nullValue == null
          && settings.emptyString == ""
          && settings.falseValue == false
          && settings.zero == 0
          && settings.emptyList == [ ]
          && settings.emptyAttrs == { };
        message = "Overlay forwarding must retain native composition and explicit empty values.";
      }
      {
        assertion =
          config.test.overlays.forced.settings == {
            value = "forced";
            conditional = "new";
            unrelated = true;
          }
          && config.test.overlays.canonicalForce.settings == { canonical = true; }
          && config.test.overlays.weak.settings == { }
          && overlays.weak.keys == [ ]
          && config.test.overlays.empty.settings == { }
          && overlays.empty.keys == [ ]
          && config.test.overlays.unset.settings == { }
          && overlays.unset.keys == [ ];
        message = "Overlay root priorities must not affect unrelated settings or revive weak sources.";
      }
      {
        assertion =
          config.test.overlays.forced.old == config.test.overlays.forced.settings
          && config.test.overlays.unset.old == { }
          && lib.all (file: lib.any (lib.hasInfix file) config.warnings) [
            "overlay-first.nix"
            "overlay-second.nix"
          ];
        message = "Overlay aliases must preserve reads and emit one standard warning per active source.";
      }
    ];
  };
}
