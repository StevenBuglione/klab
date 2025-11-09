{ lib, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  olab.laptopAsServer.enable = true;
  
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

   programs.nix-ld.enable = true;
   programs.nix-ld.libraries = with pkgs; [
     SDL
     SDL2
     SDL2_image
     SDL2_mixer
     SDL2_ttf
     SDL_image
     SDL_mixer
     SDL_ttf
     alsa-lib
     at-spi2-atk
     at-spi2-core
     atk
     bzip2
     cairo
     cups
     curlWithGnuTls
     dbus
     dbus-glib
     desktop-file-utils
     e2fsprogs
     expat
     flac
     fontconfig
     freeglut
     freetype
     fribidi
     fuse
     fuse3
     gdk-pixbuf
     glew110
     glib
     gmp
     gst_all_1.gst-plugins-base
     gst_all_1.gst-plugins-ugly
     gst_all_1.gstreamer
     gtk2
     harfbuzz
     icu
     keyutils.lib
     libGL
     libGLU
     libappindicator-gtk2
     libcaca
     libcanberra
     libcap
     libclang.lib
     libdbusmenu
     libdrm
     libgcrypt
     libgpg-error
     libidn
     libjack2
     libjpeg
     libmikmod
     libogg
     libpng12
     libpulseaudio
     librsvg
     libsamplerate
     libthai
     libtheora
     libtiff
     libudev0-shim
     libusb1
     libuuid
     libvdpau
     libvorbis
     libvpx
     libxcrypt-legacy
     libxkbcommon
     libxml2
     mesa
     nspr
     nss
     openssl
     p11-kit
     pango
     pixman
     python3
     speex
     stdenv.cc.cc
     tbb
     udev
     vulkan-loader
     wayland
     xorg.libICE
     xorg.libSM
     xorg.libX11
     xorg.libXScrnSaver
     xorg.libXcomposite
     xorg.libXcursor
     xorg.libXdamage
     xorg.libXext
     xorg.libXfixes
     xorg.libXft
     xorg.libXi
     xorg.libXinerama
     xorg.libXmu
     xorg.libXrandr
     xorg.libXrender
     xorg.libXt
     xorg.libXtst
     xorg.libXxf86vm
     xorg.libpciaccess
     xorg.libxcb
     xorg.xcbutil
     xorg.xcbutilimage
     xorg.xcbutilkeysyms
     xorg.xcbutilrenderutil
     xorg.xcbutilwm
     xorg.xkeyboardconfig
     xz
     zlib
   ];


  # Static IP on the Dell
  olab.network = {
    hostName = "dell";
    useNetworkManager = false;     # static via base networking
    dhcp = false;
    static = {
      enable = true;
      interface = "enp0s13f0u4u1";     # e.g., "eno1" or "enp3s0"
      address = "10.10.10.3";
      prefixLength = 24;
      gateway = "10.10.10.1";
      nameservers = [ "10.10.10.1" ];
    };
  };

  # Extend user groups specific to Dell
  users.users.sbuglione.extraGroups = [ "wheel"];

  # USB NIC / power server extras (unchanged from before)
  hardware.enableAllFirmware = true;
  boot.kernelModules = [ "usbnet" "cdc_ncm" "cdc_ether" "rndis_host" "r8152" "ax88179_178a" ];
  boot.kernelParams = [ "usbcore.autosuspend=-1" ];
  boot.extraModprobeConfig = ''options r8152 bEnableEEE=0'';

  services.fwupd.enable = true;
  services.hardware.bolt.enable = true;

  system.stateVersion = "25.05";
}
