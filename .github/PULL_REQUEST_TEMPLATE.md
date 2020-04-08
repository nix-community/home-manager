<!--

  Please fill the description and checklist to the best of your
  ability.

-->

### Description



### Checklist

- [ ] Code formatted with `./format`.

- [ ] Code tested through `nix-shell --pure tests -A run.all`.

- [ ] Test cases updated/added. See [example](https://github.com/rycee/home-manager/commit/f3fbb50b68df20da47f9b0def5607857fcc0d021#diff-b61a6d542f9036550ba9c401c80f00ef).

- [ ] Commit messages are formatted like

    ```
    {component}: {description}

    {long description}
    ```

    See [CONTRIBUTING](https://github.com/rycee/home-manager/blob/master/CONTRIBUTING.md#commits) for more information and [recent commit messages](https://github.com/rycee/home-manager/commits/master) for examples.

- If this PR adds a new module

  - [ ] Added myself as module maintainer. See [example](https://github.com/rycee/home-manager/blob/068ff76a10e95820f886ac46957edcff4e44621d/modules/programs/lesspipe.nix#L6).

  - [ ] Added myself and the module files to `.github/CODEOWNERS`.
