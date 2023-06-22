# ________       ___      ___    ___  ________      ________      
#|\   ___  \    |\  \    |\  \  /  /||\   __  \    |\   ____\     
#\ \  \\ \  \   \ \  \   \ \  \/  / /\ \  \|\  \   \ \  \___|_    
# \ \  \\ \  \   \ \  \   \ \    / /  \ \  \\\  \   \ \_____  \   
#  \ \  \\ \  \   \ \  \   /     \/    \ \  \\\  \   \|____|\  \  
#   \ \__\\ \__\   \ \__\ /  /\   \     \ \_______\    ____\_\  \ 
#    \|__| \|__|    \|__|/__/ /\ __\     \|_______|   |\_________\
#                        |__|/ \|__|                  \|_________|

{ config, pkgs, ... }:

let
  # bash script to let dbus know about important env variables and
  # propagate them to relevent services run at the end of sway config
  # see
  # https://github.com/emersion/xdg-desktop-portal-wlr/wiki/"It-doesn't-work"-Troubleshooting-Checklist
  # note: this is pretty much the same as  /etc/sway/config.d/nixos.conf but also restarts  
  # some user services to make sure they have the correct environment variables
  dbus-sway-environment = pkgs.writeTextFile {
    name = "dbus-sway-environment";
    destination = "/bin/dbus-sway-environment";
    executable = true;

    text = ''
  dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
  systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
  systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
      '';
  };

  # currently, there is some friction between sway and gtk:
  # https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland
  # the suggested way to set gtk settings is with gsettings
  # for gsettings to work, we need to tell it where the schemas are
  # using the XDG_DATA_DIR environment variable
  # run at the end of sway config
  configure-gtk = pkgs.writeTextFile {
      name = "configure-gtk";
      destination = "/bin/configure-gtk";
      executable = true;
      text = let
        schema = pkgs.gsettings-desktop-schemas;
        datadir = "${schema}/share/gsettings-schemas/${schema.name}";
      in ''
        export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
        gnome_schema=org.gnome.desktop.interface
        gsettings set $gnome_schema gtk-theme 'Dracula'
        '';
  };


in


{
  nixpkgs = {
    config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
    };
    # allow a collection of pakages 
    config.allowUnfree = true;
  };

  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.kernelModules = [ "amdgpu" ];

  networking.hostName = "zipos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.


  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Copenhagen";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_DK.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "da_DK.UTF-8";
    LC_IDENTIFICATION = "da_DK.UTF-8";
    LC_MEASUREMENT = "da_DK.UTF-8";
    LC_MONETARY = "da_DK.UTF-8";
    LC_NAME = "da_DK.UTF-8";
    LC_NUMERIC = "da_DK.UTF-8";
    LC_PAPER = "da_DK.UTF-8";
    LC_TELEPHONE = "da_DK.UTF-8";
    LC_TIME = "da_DK.UTF-8";
  };
  # _                       _                               
  #| |                     | |                              
  #| |__    __ _  _ __   __| |__      __  __ _  _ __   ___  
  #| '_ \  / _` || '__| / _` |\ \ /\ / / / _` || '__| / _ \ 
  #| | | || (_| || |   | (_| | \ V  V / | (_| || |   |  __/ 
  #|_| |_| \__,_||_|    \__,_|  \_/\_/   \__,_||_|    \___| 
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      amdvlk
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      intel-compute-runtime
    ];
    # To enable Vulkan support for 32-bit applications, also add:
    extraPackages32 = with pkgs; [
      pkgs.driversi686Linux.amdvlk
    ];
  };

  
  # Force radv
  environment.variables.AMD_VULKAN_ICD = "RADV";
  # Or
  environment.variables.VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";




  # enabeling wayland
  xdg = {
    portal = {
      wlr.enable = true;
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
      ];
    };
  };

# ______     ______     ______     __   __   __     ______     ______     ______    
#/\  ___\   /\  ___\   /\  == \   /\ \ / /  /\ \   /\  ___\   /\  ___\   /\  ___\   
#\ \___  \  \ \  __\   \ \  __<   \ \ \'/   \ \ \  \ \ \____  \ \  __\   \ \___  \  
# \/\_____\  \ \_____\  \ \_\ \_\  \ \__|    \ \_\  \ \_____\  \ \_____\  \/\_____\ 
#  \/_____/   \/_____/   \/_/ /_/   \/_/      \/_/   \/_____/   \/_____/   \/_____/ 

  services = {
    xserver = {
      enable = true;

      # setting cinnamon as dafult
      desktopManager.cinnamon.enable = true;
      displayManager = {
      defaultSession = "cinnamon";
      gdm.enable = true;
      # login settings
      autoLogin.enable = false;
      autoLogin.user = "zipfriis";
      };

      # X11 keymap
      layout = "us";
      xkbVariant = "";

      # set window manager 
      windowManager = {
      qtile = {
        enable = true;
        backend = "wayland";
        };
      };
      
    };
    # audio backend 
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    # self hosted media server
    #jellyfin.enable = true;
  };                                                                                


  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
#  __  __     ______     ______     ______     ______    
# /\ \/\ \   /\  ___\   /\  ___\   /\  == \   /\  ___\   
# \ \ \_\ \  \ \___  \  \ \  __\   \ \  __<   \ \___  \  
#  \ \_____\  \/\_____\  \ \_____\  \ \_\ \_\  \/\_____\ 
#   \/_____/   \/_____/   \/_____/   \/_/ /_/   \/_____/ 

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    zipfriis = {
      isNormalUser = true;
      description = "zipfriis";
      extraGroups = [ "networkmanager" "wheel" ];
      packages = with pkgs; [
        neofetch
        firefox
        vscode
        steam
        discord    
        obs-studio
        lutris
        godot_4
        kicad
        inkscape
        mpv
	      freecad

        # anonymous browsing
        i2pd
        librewolf-unwrapped
        tor-browser-bundle-bin
        qbittorrent

      ];
    };
  };

  users.defaultUserShell = pkgs.zsh;
#  ______   ______     ______     ______     ______     ______     __    __     ______    
# /\  == \ /\  == \   /\  __ \   /\  ___\   /\  == \   /\  __ \   /\ "-./  \   /\  ___\   
# \ \  _-/ \ \  __<   \ \ \/\ \  \ \ \__ \  \ \  __<   \ \  __ \  \ \ \-./\ \  \ \___  \  
#  \ \_\    \ \_\ \_\  \ \_____\  \ \_____\  \ \_\ \_\  \ \_\ \_\  \ \_\ \ \_\  \/\_____\ 
#   \/_/     \/_/ /_/   \/_____/   \/_____/   \/_/ /_/   \/_/\/_/   \/_/  \/_/   \/_____/ 
  
  
  # here we declare pakages for the system
  environment.systemPackages = with pkgs; [

    # Programs for developers
    nasm        # is a 80x86 and x86-64 assembler
    vim         # terminal text editor
    zsh         # terminal shell
    alacritty   # terminal emulator 
    unzip       # extract files which is compressed
    htop        # see dekstop utilizeation
    man         # manunals for commands
    python39    # python 3
    git         # git

    # Desktop tools 
    handbrake
    pulseaudio
    pavucontrol
    

    gnome.nautilus
    gnome.gnome-system-monitor

    # intertainment
    spotify
    

    feh
    wbg
    wget
    qpwgraph
    wofi
    polkit_gnome
    wlroots
    thefuck
    jellyfin
    ueberzug
    
    # sway
    sway
    wayland
    xdg-utils
    glib # gsettings
    dracula-theme # gtk theme
    gnome3.adwaita-icon-theme  # default gnome cursors
    swaylock
    swayidle
    grim # screenshot functionality
    slurp # screenshot functionality
    wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    bemenu # wayland clone of dmenu
    mako # notification system developed by swaywm maintainer
    wdisplays # tool to configure displays

  ];

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
  ];


  programs = {
    zsh = {
      enable = true;
      shellAliases = {
        ll = "ls -la";
        update = "sudo nixos-rebuild switch --upgrade";
        fetch = "neofetch";
      };
      ohMyZsh = {
        enable = true;
        plugins = [ "git" "thefuck" ];
        theme = "jonathan";
      };
    };
    steam = { 
      enable = true;
      remotePlay.openFirewall = true; 
      dedicatedServer.openFirewall = true;
    };
    sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };
  };
  nix.gc.automatic = true;
  nix.gc.dates = "20:00";




  system.stateVersion = "23.05"; # Did you read the comment?
}

