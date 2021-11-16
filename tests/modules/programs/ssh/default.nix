{
  ssh-defaults = ./default-config.nix;
  ssh-includes = ./includes.nix;
  ssh-match-blocks = ./match-blocks-attrs.nix;

  ssh-forwards-dynamic-valid-bind-no-asserts =
    ./forwards-dynamic-valid-bind-no-asserts.nix;
  ssh-forwards-dynamic-bind-path-with-port-asserts =
    ./forwards-dynamic-bind-path-with-port-asserts.nix;
  ssh-forwards-local-bind-path-with-port-asserts =
    ./forwards-local-bind-path-with-port-asserts.nix;
  ssh-forwards-local-host-path-with-port-asserts =
    ./forwards-local-host-path-with-port-asserts.nix;
  ssh-forwards-remote-bind-path-with-port-asserts =
    ./forwards-remote-bind-path-with-port-asserts.nix;
  ssh-forwards-remote-host-path-with-port-asserts =
    ./forwards-remote-host-path-with-port-asserts.nix;
}
