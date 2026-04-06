{
  config,
  lib,
  pkgs,
  options,
  ...
}:
let
  attrSetOfString = lib.types.attrsOf lib.types.str;
  mkDeferredDefault =
    name: extraArgs:
    lib.hm.deprecations.mkStateVersionOptionDefault (
      {
        inherit (config.home) stateVersion;
        inherit config options;
        since = "26.05";
        optionPath = [
          "test"
          "values"
          name
        ];
        legacy.value = {
          FOO = "legacy";
        };
        current.value = { };
        deferWarningToConfig = true;
      }
      // extraArgs
    );

  effectiveValue =
    stateVersionDefault: value:
    lib.optionalAttrs stateVersionDefault.shouldWarn stateVersionDefault.effectiveDefault // value;

  cases = {
    unset = {
      default = mkDeferredDefault "unset" { };
      expectedWarn = true;
      expectedPriority = true;
    };
    explicitEmpty = {
      default = mkDeferredDefault "explicitEmpty" { };
      expectedWarn = false;
      expectedPriority = false;
    };
    explicitLegacy = {
      default = mkDeferredDefault "explicitLegacy" { };
      expectedWarn = false;
      expectedPriority = false;
    };
    priorityOnlyExplicit = {
      default = mkDeferredDefault "priorityOnlyExplicit" { };
      expectedWarn = false;
      expectedPriority = false;
    };
    partial = {
      default = mkDeferredDefault "partial" {
        shouldWarn =
          { optionUsesDefaultPriority, ... }:
          optionUsesDefaultPriority
          || (config.test.values.partial != { } && !(config.test.values.partial ? FOO));
      };
      expectedWarn = true;
      expectedPriority = false;
    };
  };
in
{
  options.test.values = lib.mapAttrs (
    name: case:
    lib.mkOption {
      type = attrSetOfString;
      default = { };
      inherit (case.default) defaultText;
    }
  ) cases;

  config = {
    assertions = [
      {
        assertion = cases.unset.default.defaultText._type == "literalExpression";
        message = "Deferred mkStateVersionOptionDefault should return a literalExpression defaultText.";
      }
      {
        assertion = cases.unset.default.default == { };
        message = "Deferred mkStateVersionOptionDefault should keep the raw option default at current.value.";
      }
      {
        assertion = cases.unset.default.effectiveDefault == { FOO = "legacy"; };
        message = "Deferred mkStateVersionOptionDefault should expose the legacy effective default on old state versions.";
      }
    ]
    ++ lib.flatten (
      lib.mapAttrsToList (name: case: [
        {
          assertion = case.default.shouldWarn == case.expectedWarn;
          message = "Deferred warning logic failed for ${name}: expected shouldWarn=${builtins.toJSON case.expectedWarn} but got ${builtins.toJSON case.default.shouldWarn}";
        }
        {
          assertion = case.default.optionUsesDefaultPriority == case.expectedPriority;
          message = "Deferred priority detection failed for ${name}: expected optionUsesDefaultPriority=${builtins.toJSON case.expectedPriority} but got ${builtins.toJSON case.default.optionUsesDefaultPriority}";
        }
      ]) cases
    );

    test = {
      values = {
        explicitEmpty = { };
        explicitLegacy = {
          FOO = "legacy";
        };
        priorityOnlyExplicit.BAR = "explicit";
        partial.BAR = "partial";
      };

      asserts.warnings.expected = lib.flatten (
        lib.mapAttrsToList (name: case: lib.optional case.expectedWarn case.default.warning) cases
      );
    };

    warnings = lib.flatten (
      lib.mapAttrsToList (name: case: lib.optional case.default.shouldWarn case.default.warning) cases
    );

    home.file."result.txt".text = ''
      unsetFoo=${(effectiveValue cases.unset.default config.test.values.unset).FOO or ""}
      explicitEmptyFoo=${
        (effectiveValue cases.explicitEmpty.default config.test.values.explicitEmpty).FOO or ""
      }
      explicitLegacyFoo=${
        (effectiveValue cases.explicitLegacy.default config.test.values.explicitLegacy).FOO or ""
      }
      priorityOnlyExplicitFoo=${
        (effectiveValue cases.priorityOnlyExplicit.default config.test.values.priorityOnlyExplicit).FOO
          or ""
      }
      priorityOnlyExplicitBar=${
        (effectiveValue cases.priorityOnlyExplicit.default config.test.values.priorityOnlyExplicit).BAR
          or ""
      }
      partialFoo=${(effectiveValue cases.partial.default config.test.values.partial).FOO or ""}
      partialBar=${(effectiveValue cases.partial.default config.test.values.partial).BAR or ""}
    '';

    nmt.script = ''
      assertFileContent home-files/result.txt ${pkgs.writeText "state-version-option-default-deferred.txt" ''
        unsetFoo=legacy
        explicitEmptyFoo=
        explicitLegacyFoo=legacy
        priorityOnlyExplicitFoo=
        priorityOnlyExplicitBar=explicit
        partialFoo=legacy
        partialBar=partial
      ''}
    '';
  };
}
