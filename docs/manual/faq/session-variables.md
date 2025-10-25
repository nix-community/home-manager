# Why are the session variables not set? {#_why_are_the_session_variables_not_set}

Home Manager is only able to set session variables automatically if it
manages your Bash, Z shell, or fish shell configuration. To enable such
management you use [programs.bash.enable](#opt-programs.bash.enable),
[programs.zsh.enable](#opt-programs.zsh.enable), or [programs.fish.enable](#opt-programs.fish.enable).

If you don't want to let Home Manager manage your shell then you will
have to manually source the
`~/.nix-profile/etc/profile.d/hm-session-vars.sh` file in an appropriate
way. In Bash and Z shell this can be done by adding

``` bash
. "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
```

to your `.profile` and `.zshrc` files, respectively. The
`hm-session-vars.sh` file should work in most Bourne-like shells. For
fish shell, it is possible to source it using [the foreign-env
plugin](https://github.com/oh-my-fish/plugin-foreign-env) or using the builtin
[babelfish](https://github.com/bouk/babelfish)-translated variables:

``` bash
fenv source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" > /dev/null
# or
source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.fish"
```
