### Description

<!--

Please provide a brief description of your change.

-->

### Checklist

<!--

Please go through the following checklist before opening a non-WIP
pull-request.

Also make sure to read the guidelines found at

  https://nix-community.github.io/home-manager/#sec-guidelines

-->

- [ ] Change is backwards compatible.

- [ ] Code formatted with `nix fmt` or
      `nix-shell -p treefmt nixfmt deadnix keep-sorted nixf-diagnose --run treefmt`.

- [ ] Code tested through `nix run .#tests -- test-all` or
      `nix-shell --pure tests -A run.all`.

- [ ] Test cases updated/added. See [example](https://github.com/nix-community/home-manager/commit/f3fbb50b68df20da47f9b0def5607857fcc0d021#diff-b61a6d542f9036550ba9c401c80f00ef).

- [ ] Commit messages are formatted like

  ```
  {component}: {description}

  {long description}
  ```

  See [CONTRIBUTING](https://nix-community.github.io/home-manager/#sec-commit-style) for more information and [recent commit messages](https://github.com/nix-community/home-manager/commits/master) for examples.

- If this PR adds a new module

  - [ ] Added myself as module maintainer. See [example](https://github.com/nix-community/home-manager/blob/a51598236f23c89e59ee77eb8e0614358b0e896c/modules/programs/lesspipe.nix#L11).
  - [ ] Generate a news entry. See [News](https://nix-community.github.io/home-manager/index.xhtml#sec-news)
  - [ ] Basic tests added. See [Tests](https://nix-community.github.io/home-manager/index.xhtml#sec-tests)

- If this PR adds an exciting new feature or contains a breaking change.
  - [ ] Generate a news entry. See [News](https://nix-community.github.io/home-manager/index.xhtml#sec-news)
