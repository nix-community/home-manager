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

Home Manager targets [NixOS][] unstable and NixOS version 17.03 (the
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

    ```
    $ mkdir -m 0755 -p /nix/var/nix/{profiles,gcroots}/per-user/$USER
    ```

    since Home Manager uses these directories to manage your profile
    generations. On NixOS these should already be available.

2.  Clone the Home Manager repository into the `~/.config/nixpkgs`
    directory:

    ```
    $ git clone -b master https://github.com/rycee/home-manager ~/.config/nixpkgs/home-manager
    ```

    or

    ```
    $ git clone -b release-17.03 https://github.com/rycee/home-manager ~/.config/nixpkgs/home-manager
    ```

    depending on whether you are tracking Nixpkgs unstable or version
    17.03.

3.  Add Home Manager to your user's Nixpkgs, for example by adding it
    to the `packageOverrides` section in your
    `~/.config/nixpkgs/config.nix` file:

    ```nix
    {
      packageOverrides = pkgs: rec {
        home-manager = import ./home-manager { inherit pkgs; };
      };
    }
    ```

4.  Install the `home-manager` package:

    ```
    $ nix-env -f '<nixpkgs>' -iA home-manager
    installing ‘home-manager’
    ```

Usage
-----

The `home-manager` package installs a tool that is conveniently called
`home-manager`. This tool can apply configurations to your home
directory, list user packages installed by the tool, and list the
configuration generations.

As an example, let us set up a very simple configuration that installs
the htop and fortune packages, installs Emacs with a few extra
packages enabled, installs Firefox with Adobe Flash enabled, and
enables the user gpg-agent service.

First create a file `~/.config/nixpkgs/home.nix` containing

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
    enableAdobeFlash = true;
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };
}
```

To activate this configuration you can then run

```
$ home-manager switch
```

or if you are not feeling so lucky,

```
$ home-manager build
```

which will create a `result` link to a directory containing an
activation script and the generated home directory files.

To see available configuration options with descriptions
and usage examples run

```
$ man home-configuration.nix
```

Keeping your ~ safe from harm
-----------------------------

To configure programs and services the Home Manager must write various
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

```
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
  xsession.windowManager = "…";

  # …
}
```

in your Home Manager configuration.

[Nix]: https://nixos.org/nix/
[NixOS]: https://nixos.org/
[Nixpkgs]: https://nixos.org/nixpkgs/
