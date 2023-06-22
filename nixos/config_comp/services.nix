{ config, lib, pkgs, modulesPath, ... }:
{
    services = {
        # X server
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

        ## I2P Eepsite
        i2pd = {
        enable = true;
        ifname = "ens3";
        address = "xxxx";
        # TCP & UDP
        port = 9898;
        # TCP
        ntcp2.port = 9899;
        inTunnels = {
            myEep = {
                enable = true;
                keys = "myEep-keys.dat";
                inPort = 80;
                address = "::1";
                destination = "::1";
                port = 8081;
                # inbound.length = 1;
                # outbound.length = 1;
            };
        };
        enableIPv4 = true;
        enableIPv6 = true;
        };
  };       
}
