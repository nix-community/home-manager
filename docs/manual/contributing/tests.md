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
$ nix-build --pure --option allow-import-from-derivation false tests -A build.all
```

in the project root. List all test cases through

``` shell
$ nix-build --pure tests --option allow-import-from-derivation false -A list
```

and run an individual test, for example `alacritty-empty-settings`,
through

``` shell
$ nix-build --pure tests --option allow-import-from-derivation false -A build.alacritty-empty-settings
```

However, those invocations will impurely source the system's Nixpkgs,
and may cause failures. To run against the Nixpkgs from the `flake.lock` file,
use instead e.g.

``` shell
$ nix build --reference-lock-file flake.lock --option allow-import-from-derivation false ./tests#test-all
```

or

``` shell
$ nix build --reference-lock-file flake.lock --option allow-import-from-derivation false ./tests#test-alacritty-empty-settings
```

Some tests may be marked with `enableLegacyIfd`, those may be run by run with e.g.

``` shell
$ nix-build --pure tests --arg enableLegacyIfd true -A build.mytest
```
