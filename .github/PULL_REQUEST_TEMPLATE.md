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

- [ ] Code formatted with `./format`.

- [ ] Code tested through `nix-shell --pure tests -A run.all` or `nix develop --ignore-environment .#all` using Flakes.

- [ ] Test cases updated/added. See [example](https://github.com/nix-community/home-manager/commit/f3fbb50b68df20da47f9b0def5607857fcc0d021#diff-b61a6d542f9036550ba9c401c80f00ef).

- [ ] Commit messages are formatted like

    ```
    {component}: {description}

    {long description}
    ```

    See [CONTRIBUTING](https://nix-community.github.io/home-manager/#sec-commit-style) for more information and [recent commit messages](https://github.com/nix-community/home-manager/commits/master) for examples.

- If this PR adds a new module

  - [ ] Added myself as module maintainer. See [example](https://github.com/nix-community/home-manager/blob/068ff76a10e95820f886ac46957edcff4e44621d/modules/programs/lesspipe.nix#L6).

#### Maintainer CC

<!--
If you are updating a module, please @ people who are in its `meta.maintainers` list.
If in doubt, check `git blame` for whoever last touched something.
-->
