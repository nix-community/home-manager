# Getting started {#sec-contrib-getting-started}

If you have not previously forked Home Manager then you need to do that
first. Have a look at GitHub's [Fork a
repo](https://help.github.com/articles/fork-a-repo/) for instructions on
how to do this.

Once you have a fork of Home Manager you should create a branch starting
at the most recent `master` branch. Give your branch a reasonably
descriptive name. Commit your changes to this branch and when you are
happy with the result and it fulfills [Guidelines](#sec-guidelines) then
push the branch to GitHub and [create a pull
request](https://help.github.com/articles/creating-a-pull-request/).

Assuming your clone is at `$HOME/devel/home-manager` then you can make
the `home-manager` command use it by either

1.  overriding the default path by using the `-I` command line option:

    ``` shell
    $ home-manager -I home-manager=$HOME/devel/home-manager
    ```

    or, if using [flakes](#sec-flakes-standalone):

    ``` shell
    $ home-manager --override-input home-manager ~/devel/home-manager
    ```

    or

2.  changing the default path by ensuring your configuration includes

    ``` nix
    programs.home-manager.enable = true;
    programs.home-manager.path = "$HOME/devel/home-manager";
    ```

    and running `home-manager switch` to activate the change.
    Afterwards, `home-manager build` and `home-manager switch` will use
    your cloned repository.

The first option is good if you only temporarily want to use your clone.
