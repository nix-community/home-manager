{ pkgs, ... }:
{
  time = "2026-07-19T13:55:33+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    'programs.rclone' mounts now support a 'mountType' option that can be
    set to "nfsmount" to mount remotes via rclone's built-in NFS server
    and the system NFS client instead of FUSE. On macOS this removes the
    need for macFUSE and its kernel extension (and the Reduced Security
    boot policy the extension requires). When "nfsmount" is selected,
    'nfs-cache-type = "disk"' is added to the mount's options by default
    so NFS file handles survive rclone restarts.
  '';
}
