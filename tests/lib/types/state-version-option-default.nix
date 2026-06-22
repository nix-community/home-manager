{
  config,
  lib,
  pkgs,
  ...
}:
let
  legacyDefault = lib.hm.deprecations.mkStateVersionOptionDefault {
    stateVersion = "25.11";
    since = "26.05";
    optionPath = [
      "test"
      "values"
      "legacy"
    ];
    legacy.value = "legacy";
    current.value = "new";
  };

  newDefault = lib.hm.deprecations.mkStateVersionOptionDefault {
    stateVersion = "26.05";
    since = "26.05";
    optionPath = [
      "test"
      "values"
      "new"
    ];
    legacy.value = "legacy";
    current.value = "new";
  };

  equalDefault = lib.hm.deprecations.mkStateVersionOptionDefault {
    stateVersion = "25.11";
    since = "26.05";
    optionPath = [
      "test"
      "values"
      "equal"
    ];
    legacy.value = null;
    current.value = null;
  };
in
{
  options.test.values = {
    legacy = lib.mkOption {
      type = lib.types.str;
      inherit (legacyDefault)
        default
        defaultText
        ;
    };

    new = lib.mkOption {
      type = lib.types.str;
      inherit (newDefault)
        default
        defaultText
        ;
    };

    pinnedLegacy = lib.mkOption {
      type = lib.types.str;
      inherit (legacyDefault)
        default
        defaultText
        ;
    };

    equal = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      inherit (equalDefault)
        default
        defaultText
        ;
    };
  };

  config = {
    assertions = [
      {
        assertion = legacyDefault.defaultText._type == "literalExpression";
        message = "mkStateVersionOptionDefault should return a literalExpression defaultText.";
      }
      {
        assertion =
          lib.hasInfix ''config.home.stateVersion "26.05"'' legacyDefault.defaultText.text
          && lib.hasInfix ''"new"'' legacyDefault.defaultText.text
          && lib.hasInfix ''"legacy"'' legacyDefault.defaultText.text;
        message = "mkStateVersionOptionDefault should keep defaultText as static text instead of evaluating config.";
      }
    ];

    test.values.pinnedLegacy = "legacy";

    home.file."result.txt".text = ''
      legacy=${config.test.values.legacy}
      new=${config.test.values.new}
      pinnedLegacy=${config.test.values.pinnedLegacy}
      equal=${if config.test.values.equal == null then "null" else config.test.values.equal}
    '';

    test.asserts.evalWarnings.expected = [
      ''
        The default value of `test.values.legacy` has changed from `"legacy"` to `"new"`.
        You are currently using the legacy default (`"legacy"`) because `home.stateVersion` is less than "26.05".
        To silence this warning and keep legacy behavior, set:
          test.values.legacy = "legacy";
        To adopt the new default behavior, set:
          test.values.legacy = "new";
      ''
    ];

    nmt.script = ''
      assertFileContent home-files/result.txt ${pkgs.writeText "state-version-option-default.txt" ''
        legacy=legacy
        new=new
        pinnedLegacy=legacy
        equal=null
      ''}
    '';
  };
}
