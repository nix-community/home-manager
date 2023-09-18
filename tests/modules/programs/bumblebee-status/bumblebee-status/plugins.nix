{ pkgs, python3Packages, ... }:
with pkgs;
with python3Packages;
let
  mkPluginCfg = { name, requires ? [ ], requiresUnpackaged ? [ ], optional ? [ ]
    , warnings ? [ ], }: rec {
      inherit name requires requiresUnpackaged optional;
      warnings = let
        warn = dep:
          ''
            Plugin "${name}": Dependency `${dep}` is not known to be contained in Nixpkgs, so plugin might fail at runtime.'';
        requiresUnpackagedWarnings = map warn requiresUnpackaged;
      in warnings ++ requiresUnpackagedWarnings;
    };
in map mkPluginCfg [
  {
    name = "amixer";
    requires = [ alsa-utils ];
  }
  # {
  #   name = "apt";
  #   requiresUnpackaged = ["aptitude"];
  # }
  {
    name = "arandr";
    requires = [ tkinter arandr xorg.xrandr ];
  }
  # {
  #   name = "arch-update";
  #   requiresUnpackaged = ["checkupdates"];
  # }
  # {
  #   name = "arch_update";
  #   requiresUnpackaged = ["checkupdates"];
  # }
  # {
  #   name = "aur-update";
  #   requiresUnpackaged = ["yay"];
  # }
  { name = "battery"; }
  { name = "battery-upower"; }
  { name = "battery_upower"; }
  {
    name = "bluetooth";
    requires = [ bluez blueman dbus ];
  }
  {
    name = "bluetooth2";
    requires = [ bluez blueman dbus dbus-python ];
  }
  {
    name = "blugon";
    requires = [ blugon ];
  }
  {
    name = "brightness";
    optional = [ brightnessctl light xbacklight ];
    warnings = [
      "If you do not allow this plugin to query the system's ACPI, i.e. the plugin option `use_acpi` is set to `False`, then you need at least one of the optional dependencies."
    ];
  }
  {
    name = "caffeine";
    requires = [ xdg-utils xdotool xorg.xprop libnotify ];
  }
  {
    name = "cmus";
    requires = [ cmus ];
  }
  {
    name = "cpu";
    requires = [ psutil gnome.gnome-system-monitor ];
  }
  {
    name = "cpu2";
    requires = [ psutil lm_sensors ];
  }
  {
    name = "currency";
    requires = [ requests ];
  }
  { name = "date"; }
  { name = "datetime"; }
  {
    name = "datetimetz";
    requires = [ tzlocal pytz ];
  }
  { name = "datetz"; }
  {
    name = "deadbeef";
    requires = [ deadbeef ];
  }
  { name = "debug"; }
  {
    name = "deezer";
    requires = [ dbus-python ];
  }
  {
    name = "disk";
  }
  # {
  #   name = "dnf";
  #   requiresUnpackaged = ["dnf"];
  # }
  {
    name = "docker_ps";
    requires = [ python3Packages.docker ];
  }
  {
    name = "dunst";
    requires = [ dunst ];
  }
  {
    name = "dunstctl";
    requires = [ dunst ];
  }
  # {
  #   name = "emerge_status";
  #   requiresUnpackaged = ["emerge"];
  # }
  { name = "error"; }
  {
    name = "gcalendar";
    requires =
      [ google-api-python-client google-auth-httplib2 google-auth-oauthlib ];
  }
  {
    name = "getcrypto";
    requires = [ requests ];
  }
  {
    name = "git";
    requires = [ xcwd pygit2 ];
  }
  {
    name = "github";
    requires = [ requests ];
  }
  # {
  #   name = "gpmdp";
  #   requiresUnpackaged = ["gpmdp-remote"];
  # }
  { name = "hddtemp"; }
  { name = "hostname"; }
  { name = "http_status"; }
  {
    name = "indicator";
    requires = [ xorg.xset ];
  }
  { name = "kernel"; }
  {
    name = "keys";
  }
  # {
  #   name = "layout";
  #   requiresUnpackaged = ["libX11_unpackaged.so.6" "python3Packages.xkbgroup"];
  # }
  # {
  #   name = "layout-xkb";
  #   requiresUnpackaged = ["libX11_unpackaged.so.6" "python3Packages.xkbgroup"];
  # }
  {
    name = "layout-xkbswitch";
    requires = [ xkb-switch ];
  }
  # {
  #   name = "layout_xkb";
  #   requiresUnpackaged = ["libX11_unpackaged.so.6" "python3Packages.xkbgroup"];
  # }
  {
    name = "layout_xkbswitch";
    requires = [ xkb-switch ];
  }
  {
    name = "libvirtvms";
    requires = [ python3Packages.libvirt ];
  }
  {
    name = "load";
    requires = [ gnome.gnome-system-monitor ];
  }
  {
    name = "memory";
    requires = [ gnome.gnome-system-monitor ];
  }
  { name = "messagereceiver"; }
  {
    name = "mocp";
    requires = [ moc ];
  }
  {
    name = "mpd";
    requires = [ mpc-cli ];
  }
  {
    name = "network";
    requires = [ netifaces iw ];
  }
  {
    name = "network_traffic";
    requires = [ netifaces ];
  }
  {
    name = "nic";
    requires = [ netifaces iw ];
  }
  {
    name = "notmuch_count";
    requires = [ notmuch ];
  }
  # {
  #   name = "nvidiagpu";
  #   requiresUnpackaged = ["nvidia-smi"];
  # }
  {
    name = "octoprint";
    requires = [ tkinter ];
  }
  # {
  #   name = "optman";
  #   requiresUnpackaged = ["optimus-manager"];
  # }
  {
    name = "pacman";
    requires = [ fakeroot pacman ];
  }
  {
    name = "pamixer";
    requires = [ pamixer ];
  }
  {
    name = "persian_date";
    requires = [ jdatetime ];
  }
  { name = "pihole"; }
  {
    name = "ping";
    requires = [
      # ping
    ];
  }
  {
    name = "playerctl";
    requires = [ playerctl ];
  }
  {
    name = "pomodoro";
  }
  # {
  #   name = "portage_status";
  #   requiresUnpackaged = ["emerge"];
  # }
  # {
  #   name = "prime";
  #   requiresUnpackaged = ["prime-select"];
  # }
  {
    name = "progress";
    requires = [ pkgs.progress ];
  }
  {
    name = "publicip";
    requires = [ netifaces ];
  }
  # pulseaudio = {}; # deprecated
  {
    name = "pulsectl";
    requires = [ pulsectl ];
  }
  {
    name = "redshift";
    requires = [ redshift ];
  }
  # {
  #   name = "rofication";
  #   requiresUnpackaged = [ "rofication" ];
  # }
  {
    name = "rotation";
    requires = [ xorg.xrandr ];
  }
  { name = "rss"; }
  {
    name = "sensors";
    requires = [ lm_sensors ];
  }
  {
    name = "sensors2";
    requires = [ lm_sensors ];
  }
  { name = "shell"; }
  { name = "shortcut"; }
  {
    name = "smartstatus";
    requires = [ smartmontools ];
  }
  {
    name = "solaar";
    requires = [ solaar ];
  }
  {
    name = "spaceapi";
    requires = [ requests ];
  }
  { name = "spacer"; }
  {
    name = "speedtest";
    requires = [ python3Packages.speedtest-cli ];
  }
  {
    name = "spotify";
    requires = [ dbus-python ];
  }
  {
    name = "stock";
  }
  # {
  #   name = "sun";
  #   requires = [ requests python-dateutil ];
  #   requiresUnpackaged = [ "suntime" ];
  # }
  {
    name = "system";
    requires = [ tkinter ];
  }
  {
    name = "taskwarrior";
    requires = [ taskw ];
  }
  { name = "test"; }
  { name = "thunderbird"; }
  { name = "time"; }
  { name = "timetz"; }
  {
    name = "title";
    requires = [ i3ipc ];
  }
  { name = "todo"; }
  { name = "todo_org"; }
  { name = "traffic"; }
  {
    name = "twmn";
    requires = [
      # systemctl
    ];
  }
  { name = "uptime"; }
  {
    name = "vault";
    requires = [ pass ];
  }
  {
    name = "vpn";
    requires = [ tkinter networkmanager ];
  }
  {
    name = "watson";
    requires = [ watson ];
  }
  {
    name = "weather";
    requires = [ requests ];
  }
  { name = "xkcd"; }
  {
    name = "xrandr";
    requires = [ xorg.xrandr ];
    optional = [ i3 ];
  }
  {
    name = "yubikey";
    requires = [ python3Packages.yubico ];
  }
  { name = "zpool"; }
]
