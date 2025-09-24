# modules/common/updates.nix
{ config, lib, ... }:
let
  # adjust per host if needed (e.g., add "--impure" on the Mac until firmware is vendored)
  commonFlags = [ "--update-input" "nixpkgs" "--commit-lock-file" ];
in
{
  # Run weekly at Sun 00:00 (uses system time zone; you already set America/New_York)
  system.autoUpgrade = {
    enable = true;

    # Point at your flake so it pulls the latest nixpkgs and rebuilds this host
    # The hostname after # must match your nixosConfigurations.<host>
    flake = "path:./.#${config.networking.hostName}";

    # Update nixpkgs input & commit the new lockfile before rebuilding
    flags = commonFlags;

    # Schedule: Sunday midnight
    dates = "Sun 00:00";

    # Reboot after a successful switch if required
    allowReboot = true;
  };
}
