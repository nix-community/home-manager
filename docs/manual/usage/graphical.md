# Graphical services {#sec-usage-graphical}

Home Manager includes a number of services intended to run in a
graphical session, for example `xscreensaver` and `dunst`.
Unfortunately, such services will not be started automatically unless
you let Home Manager start your X session. That is, you have something
like

``` nix
{
  # …

  services.xserver.enable = true;

  # …
}
```

in your system configuration and

``` nix
{
  # …

  xsession.enable = true;
  xsession.windowManager.command = "…";

  # …
}
```

in your Home Manager configuration.
