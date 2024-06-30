# Introduction to Home Manager {#ch-introduction}

Home Manager is a [Nix](https://nix.dev/)-powered tool for reproducible management of the contents of users' home directories.
This includes programs, configuration files, environment variables and, well… arbitrary files.
The following example snippet of Nix code:

```nix
programs.git = {
  enable = true;
  userEmail = "joe@example.org";
  userName = "joe";
};
```

would make available to a user the `git` executable and man pages and a configuration file `~/.config/git/config`:

```ini
[user]
	email = "joe@example.org"
	name = "joe"
```

Since Home Manager is implemented in Nix, it provides several benefits:

- Contents are reproducible — a home will be the exact same every time it is built, unless of course, an intentional change is made.
  This also means you can have the exact same home on different hosts.
- Significantly faster and more powerful than various backup strategies.
- Unlike "dotfiles" repositories, Home Manager supports specifying programs, as well as their configurations.
- Supported by <http://cache.nixos.org/>, so that you don't have to build from source.
- If you do want to build some programs from source, there is hardly a tool more useful than Nix for that, and the build instructions can be neatly integrated in your Home Manager usage.
- Infinitely composable, so that values in different configuration files and build instructions can share a source of truth.
- Connects you with the [most extensive](https://repology.org/repositories/statistics/total) and [most up-to-date](https://repology.org/repositories/statistics/newest) software package repository on earth, [Nixpkgs](https://github.com/NixOS/nixpkgs).
