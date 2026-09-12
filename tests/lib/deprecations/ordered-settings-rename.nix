{ lib, ... }:

let
  evaluated = lib.evalModules {
    modules = [
      {
        imports = lib.hm.deprecations.mkSettingsRenamedOptionModules [ ] [ "settings" ] {
          preserveOrder = true;
        } [ "items" ];

        options.settings.items = lib.mkOption {
          type = lib.types.listOf lib.types.str;
        };
      }
      {
        items = lib.mkBefore [ "legacy" ];
        settings.items = [ "canonical" ];
      }
    ];
  };
in
{
  assertions = [
    {
      assertion =
        evaluated.config.settings.items == [
          "legacy"
          "canonical"
        ];
      message = "Ordered settings renames must work without a warnings option.";
    }
  ];
}
