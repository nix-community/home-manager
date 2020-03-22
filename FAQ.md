Frequently Asked Questions (FAQ)
================================

Why is there a collision error when switching generation?
---------------------------------------------------------

Home Manager currently installs packages into the user environment,
precisely as if the packages were installed through
`nix-env --install`. This means that you will get a collision error if
your Home Manager configuration attempts to install a package that you
already have installed manually, that is, packages that shows up when
you run `nix-env --query`.

For example, imagine you have the `hello` package installed in your
environment

```console
$ nix-env --query
hello-2.10
```

and your Home Manager configuration contains

    home.packages = [ pkgs.hello ];

Then attempting to switch to this configuration will result in an
error similar to

```console
$ home-manager switch
these derivations will be built:
  /nix/store/xg69wsnd1rp8xgs9qfsjal017nf0ldhm-home-manager-path.drv
[…]
Activating installPackages
replacing old ‘home-manager-path’
installing ‘home-manager-path’
building path(s) ‘/nix/store/b5c0asjz9f06l52l9812w6k39ifr49jj-user-environment’
Wide character in die at /nix/store/64jc9gd2rkbgdb4yjx3nrgc91bpjj5ky-buildenv.pl line 79.
collision between ‘/nix/store/fmwa4axzghz11cnln5absh31nbhs9lq1-home-manager-path/bin/hello’ and ‘/nix/store/c2wyl8b9p4afivpcz8jplc9kis8rj36d-hello-2.10/bin/hello’; use ‘nix-env --set-flag priority NUMBER PKGNAME’ to change the priority of one of the conflicting packages
builder for ‘/nix/store/b37x3s7pzxbasfqhaca5dqbf3pjjw0ip-user-environment.drv’ failed with exit code 2
error: build of ‘/nix/store/b37x3s7pzxbasfqhaca5dqbf3pjjw0ip-user-environment.drv’ failed
```

The solution is typically to uninstall the package from the
environment using `nix-env --uninstall` and reattempt the Home Manager
generation switch.

Why are the session variables not set?
--------------------------------------

Home Manager is only able to set session variables automatically if it
manages your Bash or Z shell configuration. If you don't want to let
Home Manager manage your shell then you will have to manually source
the

    ~/.nix-profile/etc/profile.d/hm-session-vars.sh

file in an appropriate way. In Bash and Z shell this can be done by
adding

```sh
. "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
```

to your `.profile` and `.zshrc` files, respectively. The
`hm-session-vars.sh` file should work in most Bourne-like shells.

How do set up a configuration for multiple users/machines?
----------------------------------------------------------

A typical way to prepare a repository of configurations for multiple
logins and machines is to prepare one "top-level" file for each unique
combination.

For example, if you have two machines, called "kronos" and "rhea" on
which you want to configure your user "jane" then you could create the
files

- `kronos-jane.nix`,
- `rhea-jane.nix`, and
- `common.nix`

in your repository. On the kronos and rhea machines you can then make
`~jane/.config/nixpkgs/home.nix` be a symbolic link to the
corresponding file in your configuration repository.

The `kronos-jane.nix` and `rhea-jane.nix` files follow the format

```nix
{ ... }:

{
  imports = [ ./common.nix ];

  # Various options that are specific for this machine/user.
}
```

while the `common.nix` file contains configuration shared across the
two logins. Of course, instead of just a single `common.nix` file you
can have multiple ones, even one per program or service.

You can get some inspiration from the [Post your home-manager home.nix
file!][1] Reddit thread.

[1]: https://www.reddit.com/r/NixOS/comments/9bb9h9/post_your_homemanager_homenix_file/

Why do I get an error message about `ca.desrt.dconf`?
-----------------------------------------------------

You are most likely trying to configure the GTK or Gnome Terminal but
the DBus session is not aware of the dconf service. The full error you
might get is

    error: GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name ca.desrt.dconf was not provided by any .service files

The solution on NixOS is to add

    services.dbus.packages = with pkgs; [ gnome3.dconf ];

to your system configuration.

How do I install packages from Nixpkgs unstable?
------------------------------------------------

If you are using a stable version of Nixpkgs but would like to install
some particular packages from Nixpkgs unstable then you can import the
unstable Nixpkgs and refer to its packages within your configuration.
Something like

```nix
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
Note, the package will not be affected by any package overrides,
overlays, etc.

How do I override the package used by a module?
-----------------------------------------------

By default Home Manager will install the package provided by your
chosen `nixpkgs` channel but occasionally you might end up needing to
change this package. This can typically be done in two ways.

1. If the module provides a `package` option, such as
   `programs.beets.package`, then this is the recommended way to
   perform the override. For example,

   ```
   programs.beets.package = pkgs.beets.override { enableCheck = true; };
   ```

2. If no `package` option is available, then you can typically
   override the relevant package using an [overlay][nixpkgs-overlays].

   For example, if you want to use the `programs.skim` module but use
   the `skim` package from Nixpkgs unstable, then a configuration like

   ```nix
   { pkgs, config, ... }:

   let

     pkgsUnstable = import <nixpkgs-unstable> {};

   in

   {
     programs.skim.enable = true;

     nixpkgs.overlays = [
       (self: super: {
         skim = pkgsUnstable.skim;
       })
     ];

     # …
   }
   ```

   should work OK.

[nixpkgs-overlays]: https://nixos.org/nixpkgs/manual/#chap-overlays
