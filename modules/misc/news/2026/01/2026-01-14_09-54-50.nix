{
  time = "2026-01-14T14:54:50+00:00";
  condition = true;
  message = ''
    There is a new option, 'home-manager.startAsUserService', which
    causes home-manager to set up each user's personal environment on
    demand when they log in, instead of doing all the setup work
    proactively during system boot.  Using this mode makes
    home-manager compatible with pam_mount and other situations where
    users' home directories are not available until they log in.
  '';
}
