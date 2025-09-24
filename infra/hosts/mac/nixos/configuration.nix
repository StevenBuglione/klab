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
    configurationLimit = 20;
    editor = true;

    # Use fully qualified binaries — do NOT rely on PATH here
    extraInstallCommands = ''
      set -eu
      conf=/boot/loader/loader.conf

      ${pkgs.coreutils}/bin/install -d -m 0755 /boot/loader
      ${pkgs.coreutils}/bin/touch "$conf"

      # default -> nixos (dynamic "latest")
      if ${pkgs.gnugrep}/bin/grep -q '^default ' "$conf"; then
        ${pkgs.gnused}/bin/sed -i -E 's/^default .*/default nixos/' "$conf"
      else
        echo 'default nixos' | ${pkgs.coreutils}/bin/tee -a "$conf" >/dev/null
      fi

      # timeout -> 5
      if ${pkgs.gnugrep}/bin/grep -q '^timeout ' "$conf"; then
        ${pkgs.gnused}/bin/sed -i -E 's/^timeout .*/timeout 5/' "$conf"
      else
        echo 'timeout 5' | ${pkgs.coreutils}/bin/tee -a "$conf" >/dev/null
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

