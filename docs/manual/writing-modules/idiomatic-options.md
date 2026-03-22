# Idiomatic options {#sec-idiomatic-options}

With time, a few patterns have emerged in the "shape" of some modules, with
common patterns and a shared vocabulary of options in use for Home Manager.

We've documented a few of them as do's and don'ts here.

## Shell integrations {#sec-shell-integrations}

XXX.

### Shell completion {#sec-shell-completion}

Shell completion is _not_ the duty of Home-Manager, and should instead be
packaged upstream in Nixpkgs, usually through the use of
[`installShellCompletion`](https://nixos.org/manual/nixpkgs/unstable/#installshellfiles-installshellcompletion).

To be more explicit: a module's shell integration should _not_ be to source its
completion at runtime, this is better done by generating them at build time
during packaging and placing them in their expected location.

## VCS integrations {#sec-vcs-integrations}

Similar to [shell integrations](#sec-vcs-integrations). XXX.
