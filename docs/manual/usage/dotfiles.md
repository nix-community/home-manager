# Keeping your \~ safe from harm {#sec-usage-dotfiles}

To configure programs and services Home Manager must write various
things to your home directory. To prevent overwriting any existing files
when switching to a new generation, Home Manager will attempt to detect
collisions between existing files and generated files. If any such
collision is detected the activation will terminate before changing
anything on your computer.

For example, suppose you have a wonderful, painstakingly created
`~/.config/git/config` and add

``` nix
{
  # …

  programs.git = {
    enable = true;
    userName = "Jane Doe";
    userEmail = "jane.doe@example.org";
  };

  # …
}
```

to your configuration. Attempting to switch to the generation will then
result in

``` shell
$ home-manager switch
…
Activating checkLinkTargets
Existing file '/home/jdoe/.config/git/config' is in the way
Please move the above files and try again
```

This error is about a file that Home Manager wants to manage as a
symbolic link in your home directory. It is separate from package
profile collisions, which usually mention `installPackages` or a
`collision between .../bin/...` path. For package collisions, see
[Why is there a collision error when switching generation?](#_why_is_there_a_collision_error_when_switching_generation).

## Resolving file collisions {#sec-usage-dotfiles-collisions}

The safest resolution is to inspect the existing path, move any
settings you want Home Manager to manage into your configuration, and
remove or move the unmanaged file before switching again.

For a standalone Home Manager installation, you can ask Home Manager to
move unmanaged non-symlink paths out of the way during activation:

``` shell
home-manager switch -b backup
```

With the command above, a colliding `~/.config/git/config` is moved to
`~/.config/git/config.backup` before Home Manager links the managed
file. If the backup path already exists then activation still aborts, so
choose an extension whose backup path does not already exist.

Standalone activation can also run a custom command for each collision:

``` shell
home-manager switch -B trash-put
```

The command receives the colliding path as an argument and must move or
remove that path. If both `-B` and `-b` are set, the custom command takes
precedence; the command may still use the
`HOME_MANAGER_BACKUP_EXT` environment variable set by `-b`.

When Home Manager is used as a NixOS or nix-darwin module, configure the
corresponding module options instead of passing standalone command line
flags:

``` nix
{
  home-manager.backupFileExtension = "backup";
}
```

or

``` nix
{
  home-manager.backupCommand = "${pkgs.trash-cli}/bin/trash-put";
}
```

If both {option}`home-manager.backupCommand` and
{option}`home-manager.backupFileExtension` are set, the command takes
precedence. The extension is still exported to the command as
`HOME_MANAGER_BACKUP_EXT`, so the command can use it when implementing
its own backup naming. With
{option}`home-manager.backupFileExtension`, Home Manager refuses to
replace an existing backup path unless
{option}`home-manager.overwriteBackup` is enabled:

``` nix
{
  home-manager.backupFileExtension = "backup";
  home-manager.overwriteBackup = true;
}
```

::: {.warning}
{option}`home-manager.overwriteBackup` allows activation to clobber
existing backup files. Only enable it when those backup paths are
disposable.
:::

For individual files, many file options also support `force = true`:

``` nix
{
  home.file.".config/example" = {
    source = ./example;
    force = true;
  };
}
```

This skips the collision check for the affected target and lets Home
Manager replace the existing file or link. Use it sparingly; it can
silently delete local changes.

Backup commands and backup extensions are intended for unmanaged
non-symlink paths. If the colliding target is an unmanaged symbolic
link, move it manually or use `force = true` after checking that the
link target is safe to replace.

## Advanced file behavior {#sec-usage-dotfiles-advanced}

The notes below apply to {option}`home.file` and to options based on the
same file type, such as {option}`xdg.configFile`.

When a file source is a directory, {option}`home.file.<name>.recursive`
changes how the directory is linked. With the default `recursive =
false`, the target is one symbolic link to the source directory. With
`recursive = true`, Home Manager creates a matching directory tree and
links each leaf file into it.

Recursive directory linking has special overlap behavior. A direct
duplicate target, such as two managed files both targeting `foo`, is an
error. If a recursively linked directory provides `foo/bar` and another
managed file also targets `foo/bar`, Home Manager keeps the recursive
file by default and ignores the overlapping regular file.

The {option}`home.file.<name>.onChange` hook runs after the new files
are linked. For recursive file entries, the hook is always run, so it
should be written to be safe even when no leaf file actually changed.

Normally a path assigned to {option}`home.file.<name>.source` is copied
or linked through the Nix store. To make Home Manager create a link to a
live path outside the store, use
`config.lib.file.mkOutOfStoreSymlink`:

``` nix
{ config, ... }:

{
  home.file.".config/example".source =
    config.lib.file.mkOutOfStoreSymlink ./example;
}
```

This is useful when the target should follow changes to a mutable file
or directory outside the store.
