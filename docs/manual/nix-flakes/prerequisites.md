# Prerequisites {#sec-flakes-prerequisites}

-   Install Nix 2.4 or later, or have it in `nix-shell`.

-   Enable experimental features `nix-command` and `flakes`.

    -   When using NixOS, add the following to your `configuration.nix`
        and rebuild your system.

        ``` nix
        nix = {
          package = pkgs.nixFlakes;
          extraOptions = ''
            experimental-features = nix-command flakes
          '';
        };
        ```

    -   If you are not using NixOS, add the following to `nix.conf`
        (located at `~/.config/nix/` or `/etc/nix/nix.conf`).

        ``` bash
        experimental-features = nix-command flakes
        ```

        You may need to restart the Nix daemon with, for example,
        `sudo systemctl restart nix-daemon.service`.

    -   Alternatively, you can enable flakes on a per-command basis with
        the following additional flags to `nix` and `home-manager`:

        ``` shell
        $ nix --extra-experimental-features "nix-command flakes" <sub-commands>
        $ home-manager --extra-experimental-features "nix-command flakes" <sub-commands>
        ```

-   Prepare your Home Manager configuration (`home.nix`).

    Unlike the channel-based setup, `home.nix` will be evaluated when
    the flake is built, so it must be present before bootstrap of Home
    Manager from the flake. See [Configuration Example](#sec-usage-configuration) for
    introduction about writing a Home Manager configuration.
