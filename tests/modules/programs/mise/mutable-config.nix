{
  config,
  lib,
  pkgs,
  realPkgs,
  ...
}:
let
  activationScript = pkgs.writeScript "mise-mutable-config-activation" (
    config.home.activation.miseMutableConfig.data
  );
  homeManagerConfig = config.xdg.configFile."mise/conf.d/50-home-manager.toml".source;
  mise = lib.getExe realPkgs.mise;
  userConfig = pkgs.writeText "mise-user-config" ''
    [env]
    USER_TEST = "mutable"
  '';
in
lib.mkIf config.test.enableBig {
  programs.mise = {
    package = config.lib.test.mkStubPackage { name = "mise"; };
    enable = true;
    enableMutableConfig = true;
    globalConfig.env.HM_TEST = "home-manager";
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script = ''
    assertPathNotExists home-files/.config/mise/config.toml
    assertFileExists home-files/.config/mise/conf.d/50-home-manager.toml
    assertFileContent home-files/.config/mise/conf.d/50-home-manager.toml \
      ${pkgs.writeText "mise.config.expected" ''
        [env]
        HM_TEST = "home-manager"
      ''}

    export HOME=$TMPDIR/hm-user
    export XDG_CONFIG_HOME=$HOME/.config
    export MISE_CACHE_DIR=$TMPDIR/mise-cache
    export MISE_DATA_DIR=$TMPDIR/mise-data
    export MISE_OFFLINE=1
    export MISE_STATE_DIR=$TMPDIR/mise-state
    mkdir -p $HOME/.config/mise/conf.d
    ln -s ${homeManagerConfig} $HOME/.config/mise/conf.d/50-home-manager.toml

    substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
    function run() { "$@"; }

    source $TMPDIR/activate
    assertFileExists $HOME/.config/mise/config.toml
    [[ ! -s $HOME/.config/mise/config.toml ]] \
      || fail "mutable config should initially be empty"

    MISE_YES=1 ${mise} set --global USER_TEST=mutable
    assertFileContent $HOME/.config/mise/config.toml ${userConfig}

    mkdir -p $HOME/work
    cd $HOME/work
    envOutput="$(${mise} env --shell bash)"
    [[ "$envOutput" == *"export HM_TEST=home-manager"* ]] \
      || fail "Home Manager config should be loaded"
    [[ "$envOutput" == *"export USER_TEST=mutable"* ]] \
      || fail "mutable config should be loaded"

    source $TMPDIR/activate
    assertFileContent $HOME/.config/mise/config.toml ${userConfig}
  '';
}
