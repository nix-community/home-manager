final: prev: {
  home-manager =
    prev.callPackage ./home-manager { paths = [ (toString ./.) ]; };
}
