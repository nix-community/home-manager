final: prev: {
  home-manager = final.callPackage ./home-manager { path = toString ./.; };
}
