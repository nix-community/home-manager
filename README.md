Home Manager using Nix
======================

This project provides a basic system for managing a user environment
using the [Nix][] package manager together with the Nix libraries
found in [Nixpkgs][]. Before attempting to use Home Manager please
read the warning below.

Words of warning
----------------

This project is under development. I personally use it to manage
several user configurations but it may fail catastrophically for you.
So beware!

In some cases Home Manager cannot detect whether it will overwrite a
previous manual configuration. For example, the Gnome Terminal module
will write to your dconf store and cannot tell whether a configuration
that it is about to be overwrite was from a previous Home Manager
generation or from manual configuration.

Home Manager targets [NixOS][] unstable and NixOS version 17.09 (the
current stable version), it may or may not work on other Linux
distributions and NixOS versions.

Also, the `home-manager` tool does not explicitly support rollbacks at
the moment so if your home directory gets messed up you'll have to fix
it yourself (you can attempt to run the activation script for the
desired generation).

Now when your expectations have been built up and you are eager to try
all this out you can go ahead and read the rest of this text.

Installation
------------

Currently the easiest way to install Home Manager is as follows:

1.  Make sure you have a working Nix installation. If you are not
    using NixOS then you may here have to run

    ```console
    $ mkdir -m 0755 -p /nix/var/nix/{profiles,gcroots}/per-user/$USER
    ```

    since Home Manager uses these directories to manage your profile
    generations. On NixOS these should already be available.

    Also make sure that your user is able to build and install Nix
    packages. For example, you should be able to successfully run a
    command like `nix-instantiate '<nixpkgs>' -A hello`. For a
    multi-user install of Nix this means that your user must be
    covered by the [`allowed-users`][nixAllowedUsers] Nix option. On
    NixOS you can control this option using the
    [`nix.allowedUsers`][nixosAllowedUsers] system option.

2.  Assign a temporary variable holding the URL to the appropriate
    archive. Typically this is

    ```console
    $ HM_PATH=https://github.com/rycee/home-manager/archive/master.tar.gz
    ```

    or

    ```console
    $ HM_PATH=https://github.com/rycee/home-manager/archive/release-17.09.tar.gz
    ```

    depending on whether you follow Nixpkgs unstable or version 17.09.

3.  Create an initial Home Manager configuration file:

    ```console
    $ cat > ~/.config/nixpkgs/home.nix <<EOF
    {
      programs.home-manager.enable = true;
      programs.home-manager.path = $HM_PATH;
    }
    EOF
    ```

4.  Create the first Home Manager generation:

    ```console
    $ $(nix-build $HM_PATH --no-out-link)/bin/home-manager switch
    ```

    Home Manager should now be active and available in your user
    environment.

Note, because the `HM_PATH` variable above points to the live Home
Manager repository you will automatically get updates whenever you
build a new generation. If you dislike automatic updates then perform
a Git clone of the desired branch and set `programs.home-manager.path`
to the absolute path of your clone.

Usage
-----

Home Manager is typically managed through the `home-manager` tool.
This tool can, for example, apply configurations to your home
directory, list user packages installed by the tool, and list the
configuration generations.

As an example, let us expand the initial configuration file from the
installation above to install the htop and fortune packages, install
Emacs with a few extra packages enabled, install Firefox with the
IcedTea plugin enabled, and enable the user gpg-agent service.

To satisfy the above setup we should elaborate the
`~/.config/nixpkgs/home.nix` file as follows:

```nix
{ pkgs, ... }:

{
  home.packages = [
    pkgs.htop
    pkgs.fortune
  ];

  programs.emacs = {
    enable = true;
    extraPackages = epkgs: [
      epkgs.nix-mode
      epkgs.magit
    ];
  };

  programs.firefox = {
    enable = true;
    enableIcedTea = true;
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };

  programs.home-manager = {
    enable = true;
    path = "…";
  };
}
```

To activate this configuration you can then run

```console
$ home-manager switch
```

or if you are not feeling so lucky,

```console
$ home-manager build
```

which will create a `result` link to a directory containing an
activation script and the generated home directory files.

To see available configuration options with descriptions and usage
examples run

```console
$ man home-configuration.nix
```

Keeping your ~ safe from harm
-----------------------------

To configure programs and services Home Manager must write various
things to your home directory. To prevent overwriting any existing
files when switching to a new generation, Home Manager will attempt to
detect collisions between existing files and generated files. If any
such collision is detected the activation will terminate before
changing anything on your computer.

For example, suppose you have a wonderful, painstakingly created
`~/.gitconfig` and add

```nix
{
  # …

  programs.git = {
    enable = true;
    userName = "Jane Doe";
    userEmail = "jane.doe@example.org";
  };

  # …
}
```

to your configuration. Attempting to switch to the generation will
then result in

```console
$ home-manager switch
…
Activating checkLinkTargets
Existing file '/home/jdoe/.gitconfig' is in the way
Please move the above files and try again
```

Graphical services
------------------

Home Manager includes a number of services intended to run in a
graphical session, for example `xscreensaver` and `dunst`.
Unfortunately, such services will not be started automatically unless
you let Home Manager start your X session. That is, you have something
like

```nix
{
  # …

  services.xserver.enable = true;

  # …
}
```

in your system configuration and

```nix
{
  # …

  xsession.enable = true;
  xsession.windowManager.command = "…";

  # …
}
```

in your Home Manager configuration.

[Nix]: https://nixos.org/nix/
[NixOS]: https://nixos.org/
[Nixpkgs]: https://nixos.org/nixpkgs/
[nixAllowedUsers]: https://nixos.org/nix/manual/#conf-allowed-users
[nixosAllowedUsers]: https://nixos.org/nixos/manual/options.html#opt-nix.allowedUsers
