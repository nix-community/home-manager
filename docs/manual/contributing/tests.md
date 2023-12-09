# Tests {#sec-tests}

Home Manager includes a basic test suite and it is highly recommended to
include at least one test when adding a module. Tests are typically in
the form of \"golden tests\" where, for example, a generated
configuration file is compared to a known correct file.

It is relatively easy to create tests by modeling the existing tests,
found in the `tests` project directory. For a full reference to the
functions available in test scripts, you can look at NMT's
[bash-lib](https://git.sr.ht/~rycee/nmt/tree/master/item/bash-lib).

The full Home Manager test suite can be run by executing

``` shell
$ nix-shell --pure tests -A run.all
```

in the project root. List all test cases through

``` shell
$ nix-shell --pure tests -A list
```

and run an individual test, for example `alacritty-empty-settings`,
through

``` shell
$ nix-shell --pure tests -A run.alacritty-empty-settings
```

However, those invocations will impurely source the system's nixpkgs,
and may cause failures. To run against the nixpkgs from the flake.lock,
use instead e.g.

``` shell
$ nix develop --ignore-environment .#all
```
