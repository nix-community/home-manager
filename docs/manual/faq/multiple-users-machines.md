# How to set up a configuration for multiple users/machines? {#_how_to_set_up_a_configuration_for_multiple_users_machines}

A typical way to prepare a repository of configurations for multiple
logins and machines is to prepare one \"top-level\" file for each unique
combination.

For example, if you have two machines, called \"kronos\" and \"rhea\" on
which you want to configure your user \"jane\" then you could create the
files

-   `kronos-jane.nix`,

-   `rhea-jane.nix`, and

-   `common.nix`

in your repository. On the kronos and rhea machines you can then make
`~jane/.config/home-manager/home.nix` be a symbolic link to the
corresponding file in your configuration repository.

The `kronos-jane.nix` and `rhea-jane.nix` files follow the format

``` nix
{ ... }:

{
  imports = [ ./common.nix ];

  # Various options that are specific for this machine/user.
}
```

while the `common.nix` file contains configuration shared across the two
logins. Of course, instead of just a single `common.nix` file you can
have multiple ones, even one per program or service.

You can get some inspiration from the [Post your home-manager home.nix
file!](https://www.reddit.com/r/NixOS/comments/9bb9h9/post_your_homemanager_homenix_file/)
Reddit thread.
