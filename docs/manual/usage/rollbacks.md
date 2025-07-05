# Rollbacks {#sec-usage-rollbacks}

When you perform a `home-manager switch` and discover a problem then
it is possible to _roll back_ to the previous version of your
configuration using `home-manager switch --rollback`. This will turn
the previous configuration into the current configuration.

::: {.example #ex-rollback-scenario}
### Home Manager Rollback

Imagine you have just updated Nixpkgs and switched to a new Home
Manager configuration. You discover that a package update included in
your new configuration has a bug that was not present in the previous
configuration.

You can then run `home-manager switch --rollback` to recover your
previous configuration, which includes the working version of the
package.

To see what happened above we can observe the list of Home Manager
generations before and after the rollback:

``` shell
$ home-manager generations
2024-01-04 11:56 : id 765 -> /nix/store/kahm1rxk77mnvd2l8pfvd4jkkffk5ijk-home-manager-generation (current)
2024-01-03 10:29 : id 764 -> /nix/store/2wsmsliqr5yynqkdyjzb1y57pr5q2lsj-home-manager-generation
2024-01-01 12:21 : id 763 -> /nix/store/mv960kl9chn2lal5q8lnqdp1ygxngcd1-home-manager-generation
2023-12-29 21:03 : id 762 -> /nix/store/6c0k1r03fxckql4vgqcn9ccb616ynb94-home-manager-generation
2023-12-25 18:51 : id 761 -> /nix/store/czc5y6vi1rvnkfv83cs3rn84jarcgsgh-home-manager-generation
…

$ home-manager switch --rollback
Starting home manager activation
…

$ home-manager generations
2024-01-04 11:56 : id 765 -> /nix/store/kahm1rxk77mnvd2l8pfvd4jkkffk5ijk-home-manager-generation
2024-01-03 10:29 : id 764 -> /nix/store/2wsmsliqr5yynqkdyjzb1y57pr5q2lsj-home-manager-generation (current)
2024-01-01 12:21 : id 763 -> /nix/store/mv960kl9chn2lal5q8lnqdp1ygxngcd1-home-manager-generation
2023-12-29 21:03 : id 762 -> /nix/store/6c0k1r03fxckql4vgqcn9ccb616ynb94-home-manager-generation
2023-12-25 18:51 : id 761 -> /nix/store/czc5y6vi1rvnkfv83cs3rn84jarcgsgh-home-manager-generation
…
```

:::
