{
  time = "2026-04-29T15:39:41+00:00";
  condition = true;
  message = ''
    A new `home.services` namespace has been added for nixpkgs
    modular services. Service modules shipped with packages (i.e.
    `pkgs.<name>.passthru.services.default`) drop in unchanged and are
    lifted to user systemd units. See the "Modular Services" chapter
    in the manual for details.
  '';
}
