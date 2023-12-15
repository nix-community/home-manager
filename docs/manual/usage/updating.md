# Updating {#sec-updating}

If you have installed Home Manager using the Nix channel method then
updating Home Manager is done by first updating the channel. You can
then switch to the updated Home Manager environment.

``` shell
$ nix-channel --update
…
unpacking channels...
$ home-manager switch
```
