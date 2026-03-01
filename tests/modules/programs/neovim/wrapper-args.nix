{
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  dummyDep = pkgs.runCommand "dummy-dep" { } ''
    mkdir -p $out/bin
    echo "echo dummy" > $out/bin/dummy-dep-bin
    chmod +x $out/bin/dummy-dep-bin
  '';

  dummyPlugin = pkgs.vimUtils.buildVimPlugin {
    pname = "dummy-plugin";
    version = "1.0";
    src = pkgs.writeTextDir "plugin/dummy.vim" "\" dummy";
    runtimeDeps = [ dummyDep ];
  };
in
{
  imports = [ ];
  tests.stubs.wl-clipboard = { };

  programs.neovim = {
    enable = true;
    extraName = "-my-suffix";
    withPerl = true;
    withPython3 = true;
    withRuby = true;
    withNodeJs = true;
    autowrapRuntimeDeps = true;
    waylandSupport = isLinux;
    plugins = [ dummyPlugin ];
  };

  nmt.script = ''
    nvimBin="home-path/bin/nvim"
    export PATH="$TESTED/home-path/bin:$PATH"
    export HOME="$TMPDIR/hm-user"

    assertBinaryContains() {
        local file="$TESTED/$1"
        if [[ $1 == /* ]]; then file="$1"; fi

        if ! grep -a -qF -- "$2" "$file"; then
            fail "Expected binary file '$1' to contain '$2' but it did not."
        fi
    }

    # Helper function to check host_prog provider configuration
    assertNeovimExpr() {
        local var_name="$1"
        local expected_pattern="$2"
        if ! nvim -i NONE --headless --cmd "echo $var_name" +q! 2>&1 | grep "$expected_pattern" ; then
          fail "Provider $var_name doesn't match expected pattern '$expected_pattern'"
        fi
    }

    # Ensure the main binary exists
    assertFileExists "$nvimBin"

    # 1. extraName: Check if the suffix is in the rplugin manifest path within the wrapper
    assertBinaryContains "$nvimBin" "-my-suffix/rplugin.vim"

    # 2. withPerl: Check if nvim-perl binary exists and host prog is set
    assertFileExists "home-path/bin/nvim-perl"
    assertNeovimExpr "g:perl_host_prog" "nvim-perl"

    # 3. withPython3: Check if nvim-python3 binary exists and host prog is set
    assertFileExists "home-path/bin/nvim-python3"
    assertNeovimExpr "g:python3_host_prog" "python3"

    # 4. withRuby: Check if nvim-ruby binary exists, GEM_HOME and host prog are set
    assertFileExists "home-path/bin/nvim-ruby"
    assertBinaryContains "$nvimBin" "GEM_HOME="
    assertNeovimExpr "g:ruby_host_prog" "ruby"

    # 5. withNodeJs: Check if nvim-node binary exists and host prog is set
    assertFileExists "home-path/bin/nvim-node"
    assertNeovimExpr "g:node_host_prog" "node"

    # 6. waylandSupport: Check for wl-clipboard path in wrapper's PATH modification
    # We check for the store path of wl-clipboard in the current pkgs
    ${lib.optionalString isLinux ''
      assertBinaryContains "$nvimBin" "wl-clipboard-"
    ''}

    # 7. autowrapRuntimeDeps: Check for dummyDep path in wrapper's PATH modification
    assertBinaryContains "$nvimBin" "${dummyDep}/bin"
  '';
}
