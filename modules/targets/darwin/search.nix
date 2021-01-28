{ config, lib, pkgs, ... }:

with lib;

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  cfg = config.targets.darwin;
  searchEngines = {
    Bing = "com.bing.www";
    DuckDuckGo = "com.duckduckgo";
    Ecosia = "org.ecosia.www";
    Google = "com.google.www";
    Yahoo = "com.yahoo.www";
  };
  searchId = getAttr cfg.search searchEngines;
in {
  options.targets.darwin.search = mkOption {
    type = with types; nullOr (enum (attrNames searchEngines));
    default = null;
    description = "Default search engine.";
  };

  config = mkIf (isDarwin && cfg.search != null) {
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
