# How do I install packages from Nixpkgs unstable? {#_how_do_i_install_packages_from_nixpkgs_unstable}

If you are using a stable version of Nixpkgs but would like to install
some particular packages from Nixpkgs unstable -- or some other channel
-- then you can import the unstable Nixpkgs and refer to its packages
within your configuration. Something like

``` nix
{ pkgs, config, ... }:

let

  pkgsUnstable = import <nixpkgs-unstable> {};

in

{
  home.packages = [
    pkgsUnstable.foo
  ];

  # …
}
```

should work provided you have a Nix channel called `nixpkgs-unstable`.

You can add the `nixpkgs-unstable` channel by running

``` shell
$ nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable
$ nix-channel --update
```

Note, the package will not be affected by any package overrides,
overlays, etc.
