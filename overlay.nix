final: prev: {
  home-manager = prev.callPackage ./home-manager { path = toString ./.; };
}
