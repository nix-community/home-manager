# Configuration Example {#sec-usage-configuration}

A fresh install of Home Manager will generate a minimal
`~/.config/home-manager/home.nix` file containing something like

``` nix
{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "jdoe";
  home.homeDirectory = "/home/jdoe";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
```

You can use this as a base for your further configurations.

::: {.note}
If you are not very familiar with the Nix language and NixOS modules
then it is encouraged to start with small and simple changes. As you
learn you can gradually grow the configuration with confidence.
:::

As an example, let us expand the initial configuration file to also
install the htop and fortune packages, install Emacs with a few extra
packages available, and enable the user gpg-agent service.

To satisfy the above setup we should elaborate the `home.nix` file as
follows:

``` nix
{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "jdoe";
  home.homeDirectory = "/home/jdoe";

  # Packages that should be installed to the user profile.
  home.packages = [
    pkgs.htop
    pkgs.fortune
  ];

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.emacs = {
    enable = true;
    extraPackages = epkgs: [
      epkgs.nix-mode
      epkgs.magit
    ];
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };
}
```

-   Nixpkgs packages can be installed to the user profile using
    [home.packages](#opt-home.packages).

-   The option names of a program module typically start with
    `programs.<package name>`.

-   Similarly, for a service module, the names start with
    `services.<package name>`. Note in some cases a package has both
    programs *and* service options -- Emacs is such an example.

To activate this configuration you can run

``` shell
home-manager switch
```

or if you are not feeling so lucky,

``` shell
home-manager build
```

which will create a `result` link to a directory containing an
activation script and the generated home directory files.
