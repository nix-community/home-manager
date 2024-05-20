# Standalone setup {#sec-flakes-standalone}

To prepare an initial Home Manager configuration for your logged in
user, you can run the Home Manager `init` command directly from its
flake.

For example, if you are using the unstable version of Nixpkgs or NixOS,
then to generate and activate a basic configuration run the command

``` shell
$ nix run home-manager/master -- init --switch
```

For Nixpkgs or NixOS version 23.11 run

``` shell
$ nix run home-manager/release-23.11 -- init --switch
```

This will generate a `flake.nix` and a `home.nix` file in
`~/.config/home-manager`, creating the directory if it does not exist.

If you omit the `--switch` option then the activation will not happen.
This is useful if you want to inspect and edit the configuration before
activating it.

``` shell
$ nix run home-manager/$branch -- init
$ # Edit files in ~/.config/home-manager
$ nix run home-manager/$branch -- init --switch
```

Where `$branch` is one of `master` or `release-23.11`.

After the initial activation has completed successfully then building
and activating your flake-based configuration is as simple as

``` shell
$ home-manager switch
```

It is possible to override the default configuration directory, if you
want. For example,

``` shell
$ nix run home-manager/$branch -- init --switch ~/hmconf
$ # And after the initial activation.
$ home-manager switch --flake ~/hmconf
```

::: {.note}
The flake inputs are not automatically updated by Home Manager. You need
to use the standard `nix flake update` command for that.

If you only want to update a single flake input, then the command
`nix flake lock --update-input <input>` can be used.

You can also pass flake-related options such as `--recreate-lock-file`
or `--update-input <input>` to `home-manager` when building or
switching, and these options will be forwarded to `nix build`. See the
[NixOS Wiki page](https://wiki.nixos.org/wiki/Flakes) for details.
:::
