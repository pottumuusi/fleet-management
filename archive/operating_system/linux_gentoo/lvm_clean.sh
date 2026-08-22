#!/bin/bash -e

lvremove /dev/vg01/root
lvremove /dev/vg01/home
vgremove vg01
pvremove /dev/sda3
