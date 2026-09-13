{ lib, ... }:

let
  eval =
    modules:
    lib.evalModules {
      modules = [
        {
          options.warnings = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        }
      ]
      ++ modules;
    };

  renamed = {
    options.test.renamed = {
      settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.raw;
        default = { };
      };
    };
  };

  renamedModule =
    args:
    builtins.head (
      lib.hm.deprecations.mkSettingsRenamedOptionModules
        [ "test" "renamed" ]
        [ "test" "renamed" "settings" ]
        { priority = 1400; }
        [
          (
            {
              old = "old";
              new = "value";
            }
            // args
          )
        ]
    );

  overlaid =
    value:
    eval [
      renamed
      (
        { options, ... }:
        let
          overlay = lib.hm.deprecations.mkSettingsOverlay {
            inherit options;
            from = [
              "test"
              "renamed"
              "extraConfig"
            ];
            to = [
              "test"
              "renamed"
              "settings"
            ];
          };
        in
        {
          imports = [
            overlay.module
            (renamedModule { shadowed = lib.elem "value" overlay.keys; })
          ];
        }
      )
      {
        test.renamed = {
          old = lib.mkForce "legacy";
          extraConfig = lib.mkOptionDefault { inherit value; };
        };
      }
    ];

  renamedCases = {
    preservePriority = eval [
      renamed
      {
        imports =
          lib.hm.deprecations.mkSettingsRenamedOptionModules
            [ "test" "renamed" ]
            [ "test" "renamed" "settings" ]
            { }
            [
              {
                old = "old";
                new = "native";
              }
            ];
        test.renamed = {
          old = lib.mkForce "legacy";
          settings.native = lib.mkDefault "canonical";
        };
      }
    ];
    rootDefaultActive = eval [
      renamed
      (renamedModule { })
      {
        test.renamed.old = "legacy";
        test.renamed.settings = lib.mkDefault {
          value = "canonical";
          unrelated = true;
        };
      }
    ];
    weak = eval [
      renamed
      (renamedModule { })
      { test.renamed.old = lib.mkOverride 1501 "ignored"; }
    ];
    optionDefault = eval [
      renamed
      (renamedModule { })
      { test.renamed.old = lib.mkOptionDefault "legacy"; }
    ];
    rootDefault = eval [
      renamed
      (renamedModule { })
      { test.renamed.settings = lib.mkDefault { value = "canonical"; }; }
    ];
    unset = eval [
      renamed
      (renamedModule { fallback = "fallback"; })
    ];
    ordinary = eval [
      renamed
      (renamedModule { })
      {
        config.test.renamed = {
          old = lib.mkForce "legacy";
          settings.value = "canonical";
        };
      }
    ];
    mkDefault = eval [
      renamed
      (renamedModule { })
      {
        config.test.renamed = {
          old = lib.mkForce "legacy";
          settings.value = lib.mkDefault "canonical";
        };
      }
    ];
    forced = eval [
      renamed
      (renamedModule { })
      {
        config.test.renamed = {
          old = "legacy";
          settings.value = lib.mkForce "canonical";
        };
      }
    ];
    rootForce = eval [
      renamed
      (renamedModule { fallback = "fallback"; })
      {
        config.test.renamed = {
          old = "legacy";
          settings = lib.mkForce { };
        };
      }
    ];
    shadowed = eval [
      renamed
      (renamedModule { shadowed = true; })
      { config.test.renamed.old = "legacy"; }
    ];
    conflict = eval [
      renamed
      (renamedModule { })
      { config.test.renamed.old = lib.mkDefault "first"; }
      { config.test.renamed.old = lib.mkAfter "second"; }
    ];
  };

  ordered = eval [
    {
      imports = lib.hm.deprecations.mkSettingsRenamedOptionModules [ "old" ] [ "settings" ] {
        priority = 75;
        preserveOrder = true;
      } [ "items" ];
      options.settings = lib.mkOption { type = lib.types.attrsOf (lib.types.listOf lib.types.str); };
      config.settings.items = lib.mkOverride 75 [ "middle" ];
    }
    { old.items = lib.mkBefore [ "first" ]; }
    { old.items = lib.mkAfter [ "last" ]; }
  ];

  hasWarning = result: path: lib.any (lib.hasInfix path) result.config.warnings;
in
{
  assertions = [
    {
      assertion = renamedCases.preservePriority.config.test.renamed.settings.native == "legacy";
      message = "Without a priority override, renames must retain the source priority.";
    }
    {
      assertion = renamedCases.rootDefaultActive.config.test.renamed.settings == { value = "legacy"; };
      message = "An active legacy source retains its precedence over whole-settings defaults.";
    }
    {
      assertion =
        renamedCases.weak.config.test.renamed.settings == { } && renamedCases.weak.config.warnings == [ ];
      message = "Sources weaker than an option default must neither forward nor warn.";
    }
    {
      assertion = renamedCases.optionDefault.config.test.renamed.settings.value == "legacy";
      message = "Sources at exactly the option-default priority must still forward.";
    }
    {
      assertion = renamedCases.rootDefault.config.test.renamed.settings.value == "canonical";
      message = "Unused aliases must not suppress whole-settings defaults.";
    }
    {
      assertion =
        (overlaid null).config.test.renamed.settings.value == null
        && (overlaid "").config.test.renamed.settings.value == "";
      message = "Overlay presence, including null and empty values, must suppress even forced legacy values.";
    }
    {
      assertion =
        (overlaid (lib.mkIf false (throw "disabled overlay was forced"))).config.test.renamed.settings.value
        == "legacy";
      message = "An inactive overlay definition must not suppress the forwarded legacy value.";
    }
    {
      assertion = builtins.length (overlaid null).config.warnings == 2;
      message = "Shadowing an overlaid key must not suppress its deprecation warning.";
    }
    {
      assertion = renamedCases.unset.config.test.renamed.old == "fallback";
      message = "Renamed aliases must read their fallback when unset.";
    }
    {
      assertion = renamedCases.ordinary.config.test.renamed.old == "canonical";
      message = "Renamed aliases must read back the winning canonical value.";
    }
    {
      assertion = renamedCases.mkDefault.config.test.renamed.settings.value == "canonical";
      message = "Canonical mkDefault values must beat forwarded forced legacy values.";
    }
    {
      assertion = renamedCases.forced.config.test.renamed.old == "canonical";
      message = "Forced canonical values must beat legacy values.";
    }
    {
      assertion = renamedCases.rootForce.config.test.renamed.old == "fallback";
      message = "Renamed aliases must read fallback through a forced root with no leaf.";
    }
    {
      assertion = renamedCases.shadowed.config.test.renamed.settings == { };
      message = "Shadowed renamed settings must not forward legacy values.";
    }
    {
      assertion = renamedCases.conflict.config.test.renamed.settings.value == "second";
      message = "Renamed helpers must resolve conflicting legacy definitions before forwarding.";
    }
    {
      assertion =
        ordered.config.settings.items == [
          "first"
          "middle"
          "last"
        ];
      message = "The configured forwarding priority must compose with preserved list ordering.";
    }
    {
      assertion = hasWarning renamedCases.shadowed "test.renamed.old";
      message = "Shadowed aliases must still emit deprecation warnings.";
    }
  ];
}
