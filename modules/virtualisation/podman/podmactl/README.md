# podmactl

`podmactl` is a script to manage the podman machines declared in Home
Manager.

## How it works

`main()` is a (hopefully) straight-forward method to read, but the gist of it is:

1. The declared machines and their configuration are passed in.
2. Existing machines and their configuration are listed.
3. A diff is made from the declared machines and existing machines.
4. New machines are added.
5. Existing machines are updated.
6. Old machines are removed.
7. The machine declared as `active` is started (if necessary).

## Developing

Enter a devshell with `nix-shell`.

Make your changes and then run

```
# Code autoformatting
black .

# Unittests
python -m unittest
```
