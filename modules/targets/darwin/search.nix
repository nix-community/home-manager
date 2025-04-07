{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.targets.darwin;
  searchEngines = {
    Bing = "com.bing.www";
    DuckDuckGo = "com.duckduckgo";
    Ecosia = "org.ecosia.www";
    Google = "com.google.www";
    Yahoo = "com.yahoo.www";
  };
  searchId = lib.getAttr cfg.search searchEngines;
in
{
  options.targets.darwin.search = lib.mkOption {
    type = with lib.types; nullOr (enum (lib.attrNames searchEngines));
    default = null;
    description = "Default search engine.";
  };

  config = lib.mkIf (cfg.search != null) {
    assertions = [
      (lib.hm.assertions.assertPlatform "targets.darwin.search" pkgs lib.platforms.darwin)
    ];

    targets.darwin.defaults = {
      NSGlobalDomain.NSPreferredWebServices = {
        NSWebServicesProviderWebSearch = {
          NSDefaultDisplayName = cfg.search;
          NSProviderIdentifier = searchId;
        };
      };
      "com.apple.Safari".SearchProviderIdentifier = searchId;
    };
  };
}
