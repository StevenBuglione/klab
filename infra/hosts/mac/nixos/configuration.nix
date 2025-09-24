{ lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./apple-silicon-support
  ];

  klab.laptopAsServer.enable = false;  # it's a desktop-style server; flip if needed

  klab.network = {
    hostName = "mac";
    useNetworkManager = false;         # simple static
    dhcp = false;
    static = {
      enable = true;
      interface = "end0";
      address = "10.10.10.5";
      prefixLength = 24;
      gateway = "10.10.10.1";
      nameservers = [ "10.10.10.1" ];
    };
  };

  klab.hummingbot.docker = {
    enable = true;
    user = "hummingbot";
    mode = "rootful";
  };

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 20;   # show more entries
    editor = true;

    # Older channels: use this to enforce loader.conf content on the ESP
    extraInstallCommands = ''
      set -eu
      conf=/boot/loader/loader.conf

      # ensure file exists
      install -d -m 0755 /boot/loader
      touch "$conf"

      # set default to dynamic "nixos" (latest entry), not a pinned generation
      if grep -q '^default ' "$conf"; then
        sed -i -E 's/^default .*/default nixos/' "$conf"
      else
        echo 'default nixos' >> "$conf"
      fi

      # set a visible menu timeout
      if grep -q '^timeout ' "$conf"; then
        sed -i -E 's/^timeout .*/timeout 5/' "$conf"
      else
        echo 'timeout 5' >> "$conf"
      fi
    '';
  };

  # If available on your channel this also sets the menu timeout; harmless if ignored:
  boot.loader.timeout = 5;

  users.users.hummingbot.extraGroups = [ "wheel" "networkmanager" "docker" ];

  # Asahi firmware note:
  # hardware.asahi.peripheralFirmwareDirectory = ./firmware;  # if you vendor it for pure builds

  environment.systemPackages = with pkgs; [ ethtool usbutils pciutils ];
  
  system.autoUpgrade.flags = [ "--update-input" "nixpkgs" "--commit-lock-file" "--impure" ];
  system.stateVersion = "25.11";
}

