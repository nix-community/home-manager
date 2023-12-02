# Using Home Manager {#ch-usage}

Your use of Home Manager is centered around the configuration file,
which is typically found at `~/.config/home-manager/home.nix` in the
standard installation or `~/.config/home-manager/flake.nix` in a Nix
flake based installation.

::: {.note}
The default configuration used to be placed in `~/.config/nixpkgs`¸ so
you may see references to that elsewhere. The old directory still works
but Home Manager will print a warning message when used.
:::

This configuration file can be *built* and *activated*.

Building a configuration produces a directory in the Nix store that
contains all files and programs that should be available in your home
directory and Nix user profile, respectively. The build step also checks
that the configuration is valid and it will fail with an error if you,
for example, assign a value to an option that does not exist or assign a
value of the wrong type. Some modules also have custom assertions that
perform more detailed, module specific, checks.

Concretely, if your configuration contains

``` nix
programs.emacs.enable = "yes";
```

then building it, for example using `home-manager build`, will result in
an error message saying something like

```console
$ home-manager build
error: A definition for option `programs.emacs.enable' is not of type `boolean'. Definition values:
- In `/home/jdoe/.config/home-manager/home.nix': "yes"
(use '--show-trace' to show detailed location information)
```

The message indicates that you must provide a Boolean value for this
option, that is, either `true` or `false`. The documentation of each
option will state the expected type, for
[programs.emacs.enable](#opt-programs.emacs.enable) you will see "Type: boolean". You
there also find information about the default value and a description of
the option. You can find the complete option documentation in
[Home Manager Configuration Options](#ch-options) or directly in the terminal by running

``` shell
man home-configuration.nix
```

Once a configuration is successfully built, it can be activated. The
activation performs the steps necessary to make the files, programs, and
services available in your user environment. The `home-manager switch`
command performs a combined build and activation.

```{=include=} sections
usage/configuration.md
usage/rollbacks.md
usage/dotfiles.md
usage/graphical.md
usage/updating.md
```
