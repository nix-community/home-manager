{ lib, ... }:
let
  evaluate =
    args: modules:
    (lib.evalModules {
      modules = [
        {
          options.settings = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };
          options.warnings = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        }
        (lib.hm.deprecations.mkSettingsChangedOptionModule (
          {
            from = [ "legacy" ];
            to = [ "settings" ];
            key = "native.key";
            oldOption.default = "none";
            convert = value: if value == "old" then 7 else throw "unexpected legacy value";
          }
          // args
        ))
      ]
      ++ modules;
    }).config;

  forwarded = evaluate { } [
    { legacy = lib.mkDefault "discarded"; }
    {
      _file = "legacy-source.nix";
      legacy = lib.mkForce "old";
    }
  ];
  overridden = evaluate { } [
    {
      legacy = lib.mkForce "old";
      settings."native.key" = lib.mkDefault 9;
    }
  ];
  forcedRoot = evaluate { } [
    {
      legacy = "old";
      settings = lib.mkForce { };
    }
  ];
  unused = evaluate { convert = _: throw "unused conversion forced"; } [ ];
  optionDefault = evaluate { convert = _: throw "option default conversion forced"; } [
    { legacy = lib.mkOptionDefault "ignored"; }
  ];
  weak = evaluate { convert = _: throw "weak conversion forced"; } [
    { legacy = lib.mkOverride 1501 "ignored"; }
  ];
  shadowed = evaluate {
    shadowed = true;
    convert = _: throw "shadowed conversion forced";
  } [ { legacy = "old"; } ];
  priority =
    evaluate
      {
        priority = 75;
        applyDefault = _: throw "default predicate called for ordinary definition";
      }
      [
        {
          legacy = "old";
          settings."native.key" = 9;
        }
      ];
  listArgs = {
    oldOption = {
      default = [ ];
      type = lib.types.listOf lib.types.str;
    };
    applyDefault = value: value != [ ];
    convert = lib.length;
  };
  defaultList = evaluate listArgs [ { legacy = lib.mkOptionDefault [ "script" ]; } ];
  emptyList = evaluate (listArgs // { convert = _: throw "empty default conversion forced"; }) [ ];
  nested = evaluate {
    to = [
      "settings"
      "section"
    ];
    key = "value";
  } [ { legacy = "old"; } ];
in
{
  assertions = [
    {
      assertion = forwarded.settings == { "native.key" = 7; };
      message = "Conversion must use winning legacy definitions and preserve literal dotted keys.";
    }
    {
      assertion =
        lib.length forwarded.warnings == 1
        && lib.hasInfix "legacy-source.nix" (lib.head forwarded.warnings)
        && lib.hasInfix "has been changed to `settings.\"native.key\"'" (lib.head forwarded.warnings);
      message = "Converted options must name the exact destination, quote literal dotted keys, and retain source attribution.";
    }
    {
      assertion = overridden.legacy == "old" && overridden.settings."native.key" == 9;
      message = "Converted options retain legacy reads while canonical per-setting defaults win.";
    }
    {
      assertion = forcedRoot.legacy == "old" && forcedRoot.settings == { };
      message = "Whole-settings forcing must not change legacy reads.";
    }
    {
      assertion = unused.settings == { } && unused.warnings == [ ];
      message = "Unused converted options must neither evaluate the converter nor warn.";
    }
    {
      assertion =
        optionDefault.settings == { }
        && optionDefault.warnings == [ ]
        && weak.settings == { }
        && weak.warnings == [ ];
      message = "Unselected option defaults and weaker definitions must neither convert nor warn.";
    }
    {
      assertion = shadowed.settings == { } && lib.length shadowed.warnings == 1;
      message = "Shadowed conversions must remain lazy without suppressing the warning.";
    }
    {
      assertion = priority.settings."native.key" == 7;
      message = "The forwarding priority must be configurable without evaluating the default predicate for stronger definitions.";
    }
    {
      assertion =
        defaultList.settings."native.key" == 1
        && defaultList.legacy == [ "script" ]
        && lib.length defaultList.warnings == 1;
      message = "Selected option-default list values must convert, warn, and retain typed legacy reads.";
    }
    {
      assertion = emptyList.settings == { } && emptyList.warnings == [ ];
      message = "Unselected empty defaults must not evaluate the converter or warn.";
    }
    {
      assertion =
        nested.settings.section.value == 7
        && lib.hasInfix "has been changed to `settings.section.value'" (lib.head nested.warnings);
      message = "Nested settings paths must forward the converted value and name the complete destination.";
    }
  ];
}
