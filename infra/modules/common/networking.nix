{ config, lib, ... }:
let
  inherit (lib) mkOption mkEnableOption types mkIf mkMerge;
in
{
  options.olab.network = {
    hostName = mkOption {
      type = types.str;
      default = "nixos";
      description = "System hostname";
    };

    # Choose a manager; defaults work for most laptops.
    useNetworkManager = mkOption {
      type = types.bool;
      default = true;
      description = "Use NetworkManager instead of basic networking.* options";
    };

    # Simple DHCP toggle when not using NetworkManager (or as a fallback).
    dhcp = mkOption {
      type = types.bool;
      default = true;
      description = "Enable DHCP globally if not using NetworkManager or for quick setups";
    };

    # Static IPv4 (single interface helper).
    static = {
      enable = mkEnableOption "configure a single static IPv4";
      interface = mkOption { type = types.str; default = "end0"; };
      address = mkOption { type = types.str; default = ""; };
      prefixLength = mkOption { type = types.int; default = 24; };
      gateway = mkOption { type = types.str; default = ""; };
      nameservers = mkOption { type = types.listOf types.str; default = [ "1.1.1.1" "8.8.8.8" ]; };
    };
  };

  config = mkMerge [
    {
      networking.hostName = config.olab.network.hostName;
    }

    # NetworkManager path
    (mkIf config.olab.network.useNetworkManager {
      networking.networkmanager.enable = true;
      # If you still want DHCP via NM, leave static.disable
      networking.useDHCP = config.olab.network.dhcp;
    })

    # Non-NM path (basic networking.*)
    (mkIf (!config.olab.network.useNetworkManager) {
      networking.useDHCP = config.olab.network.dhcp;
    })

    # Static helper (applies regardless of NM off/on; useful for servers without NM)
    (mkIf config.olab.network.static.enable {
      networking.useDHCP = false;
      networking.interfaces.${config.olab.network.static.interface}.ipv4.addresses = [{
        address = config.olab.network.static.address;
        prefixLength = config.olab.network.static.prefixLength;
      }];
      networking.defaultGateway = config.olab.network.static.gateway;
      networking.nameservers = config.olab.network.static.nameservers;
    })
  ];
}
