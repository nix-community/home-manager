{ realPkgs, ... }:

{
  programs.git = {
    enable = true;
    hooks = { pre-commit = ./git-pre-commit-hook.sh; };
  };

  nmt.script = ''
    function getGitConfig() {
      ${realPkgs.gitMinimal}/bin/git config \
        --file $TESTED/home-files/.config/git/config \
        --get $1
    }

    assertFileExists home-files/.config/git/config
    hookPath=$(getGitConfig core.hooksPath)
    assertLinkExists $hookPath/pre-commit

    actual="$(readlink "$hookPath/pre-commit")"
    expected="${./git-pre-commit-hook.sh}"
    if [[ $actual != $expected ]]; then
      fail "Symlink $hookPath/pre-commit should point to $expected via the Nix store, but it actually points to $actual."
    fi
  '';
}
