#!/bin/bash

rm -r ~/.config/pulse/
pulseaudio -k && sudo alsa force-reload
sudo reboot
