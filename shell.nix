let
  nixpkgs = (
    import (
      let
        lock = builtins.fromJSON (builtins.readFile ./flake.lock);
        n = lock.nodes.nixpkgs.locked;
      in
      fetchTarball {
        url = "https://github.com/${n.owner}/${n.repo}/archive/${n.rev}.tar.gz";
        sha256 = n.narHash;
      }
    ) { }
  );
in
nixpkgs.callPackage ./home-manager { }
