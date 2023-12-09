# Rollbacks {#sec-usage-rollbacks}

While the `home-manager` tool does not explicitly support rollbacks at
the moment it is relatively easy to perform one manually. The steps to
do so are

1.  Run `home-manager generations` to determine which generation you
    wish to rollback to:

    ``` shell
    $ home-manager generations
    2018-01-04 11:56 : id 765 -> /nix/store/kahm1rxk77mnvd2l8pfvd4jkkffk5ijk-home-manager-generation
    2018-01-03 10:29 : id 764 -> /nix/store/2wsmsliqr5yynqkdyjzb1y57pr5q2lsj-home-manager-generation
    2018-01-01 12:21 : id 763 -> /nix/store/mv960kl9chn2lal5q8lnqdp1ygxngcd1-home-manager-generation
    2017-12-29 21:03 : id 762 -> /nix/store/6c0k1r03fxckql4vgqcn9ccb616ynb94-home-manager-generation
    2017-12-25 18:51 : id 761 -> /nix/store/czc5y6vi1rvnkfv83cs3rn84jarcgsgh-home-manager-generation
    …
    ```

2.  Copy the Nix store path of the generation you chose, e.g.,

        /nix/store/mv960kl9chn2lal5q8lnqdp1ygxngcd1-home-manager-generation

    for generation 763.

3.  Run the `activate` script inside the copied store path:

    ``` shell
    $ /nix/store/mv960kl9chn2lal5q8lnqdp1ygxngcd1-home-manager-generation/activate
    Starting home manager activation
    …
    ```
