# Shared users; hosts can add more groups with mkAfter/mkMerge
{ config, lib, pkgs, ... }:
let
  defaultShell = pkgs.bashInteractive;
in
{
  users.users.hummingbot = {
    isNormalUser = true;
    description = "Steven Buglione";
    shell = defaultShell;
    # Keep minimal here; host files can append:
    extraGroups = lib.mkDefault [ "wheel"];
    linger = true;

    subUidRanges = [ { startUid = 100000; count = 65536; } ];
    subGidRanges = [ { startGid = 100000; count = 65536; } ];
  };

    users.users."hummingbot".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIADXEW0ESKUfvgzAYIuHH/Rehcvhm8j4op7VlpLClfvC" 
  ];

    # Ensure newuidmap/newgidmap are setuid (so they can write uid_map/gid_map)
  security.wrappers.newuidmap = {
    source = "${pkgs.uidmap}/bin/newuidmap";
    owner = "root"; group = "root"; setuid = true;
  };
  security.wrappers.newgidmap = {
    source = "${pkgs.uidmap}/bin/newgidmap";
    owner = "root"; group = "root"; setuid = true;
  };

  # Allow unprivileged user namespaces (belt & suspenders)
  boot.kernel.sysctl."kernel.unprivileged_userns_clone" = 1;

}
