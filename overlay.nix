self: super: {
  home-manager = super.callPackage ./home-manager { path = toString ./.; };
}
