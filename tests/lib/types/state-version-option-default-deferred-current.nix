{
  config,
  lib,
  pkgs,
  options,
  ...
}:
let
  attrSetOfString = lib.types.attrsOf lib.types.str;
  currentDefault = lib.hm.deprecations.mkStateVersionOptionDefault {
    inherit (config.home) stateVersion;
    inherit config options;
    since = "26.05";
    optionPath = [
      "test"
      "values"
      "current"
    ];
    legacy.value = {
      FOO = "legacy";
    };
    current.value = { };
    deferWarningToConfig = true;
  };
in
{
  options.test.values.current = lib.mkOption {
    type = attrSetOfString;
    default = { };
    inherit (currentDefault) defaultText;
  };

  config = {
    home.stateVersion = "26.05";

    assertions = [
      {
        assertion = currentDefault.default == { };
        message = "Deferred mkStateVersionOptionDefault should keep the raw option default at current.value on current state versions.";
      }
      {
        assertion = currentDefault.effectiveDefault == { };
        message = "Deferred mkStateVersionOptionDefault should expose current.value as the effective default on current state versions.";
      }
      {
        assertion = currentDefault.optionUsesDefaultPriority;
        message = "Deferred mkStateVersionOptionDefault should still detect default priority on current state versions.";
      }
      {
        assertion = !currentDefault.shouldWarn;
        message = "Deferred mkStateVersionOptionDefault should not warn on current state versions.";
      }
    ];

    test.asserts.warnings.expected = [ ];

    home.file."result.txt".text = ''
      currentFoo=${currentDefault.effectiveDefault.FOO or ""}
    '';

    nmt.script = ''
      assertFileContent home-files/result.txt ${pkgs.writeText "state-version-option-default-deferred-current.txt" ''
        currentFoo=
      ''}
    '';
  };
}
