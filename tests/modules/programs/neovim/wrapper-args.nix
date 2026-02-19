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
  imports = [ ./stubs.nix ];
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
    initLua="home-files/.config/nvim/init.lua"

    assertBinaryContains() {
        local file="$TESTED/$1"
        if [[ $1 == /* ]]; then file="$1"; fi

        if ! grep -a -qF -- "$2" "$file"; then
            fail "Expected binary file '$1' to contain '$2' but it did not."
        fi
    }

    # Ensure the main binary exists
    assertFileExists "$nvimBin"

    # 1. extraName: Check if the suffix is in the rplugin manifest path within the wrapper
    assertBinaryContains "$nvimBin" "-my-suffix/rplugin.vim"

    # 2. withPerl: Check if nvim-perl binary exists and host prog is set in init.lua
    assertFileExists "home-path/bin/nvim-perl"
    assertFileContains "$initLua" "perl_host_prog="

    # 3. withPython3: Check if nvim-python3 binary exists and host prog is set in init.lua
    assertFileExists "home-path/bin/nvim-python3"
    assertFileContains "$initLua" "python3_host_prog="

    # 4. withRuby: Check if nvim-ruby binary exists, GEM_HOME is in wrapper, host prog in init.lua
    assertFileExists "home-path/bin/nvim-ruby"
    assertBinaryContains "$nvimBin" "GEM_HOME="
    assertFileContains "$initLua" "ruby_host_prog="

    # 5. withNodeJs: Check if nvim-node binary exists and host prog is set in init.lua
    assertFileExists "home-path/bin/nvim-node"
    assertFileContains "$initLua" "node_host_prog="

    # 6. waylandSupport: Check for wl-clipboard path in wrapper's PATH modification
    # We check for the store path of wl-clipboard in the current pkgs
    ${lib.optionalString isLinux ''
      assertBinaryContains "$nvimBin" "wl-clipboard-"
    ''}

    # 7. autowrapRuntimeDeps: Check for dummyDep path in wrapper's PATH modification
    assertBinaryContains "$nvimBin" "${dummyDep}/bin"
  '';
}
