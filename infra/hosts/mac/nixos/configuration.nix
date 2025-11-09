{ lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./apple-silicon-support
  ];

  olab.laptopAsServer.enable = false;  # it's a desktop-style server; flip if needed

  boot.loader = {
    efi.canTouchEfiVariables = false;

    grub = {
      enable = true;
      efiSupport = true;
      devices = [ "nodev" ];
      efiInstallAsRemovable = true;
      timeout = 5;                
    };
  };

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

  olab.network = {
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

  # Dedicated database storage on the external 3.6T drive.
  fileSystems."/srv/dbdata" = {
    device = "/dev/disk/by-uuid/91701bc4-9342-4a51-a8e6-3fc3ae14d939";
    fsType = "ext4";
    options = [ "noatime" "nodiratime" ];
    neededForBoot = false;
  };


  users.users.sbuglione.extraGroups = [ "wheel" ];

  
  system.autoUpgrade.flags = [ "--update-input" "nixpkgs" "--commit-lock-file" "--impure" ];
  system.stateVersion = "25.11";
}
