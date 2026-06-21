# ec573 - Amiga 500 8MB Z2 DRAM + 2 channel IDE controller

## Device description
The ecc0 573 - or ec573 - is an Amiga 500 internal 8MB DRAM Zorro II expansion with 2 channel autoboot IDE controller sitting under the MC68000 CPU. It does fit into a standard Amiga 500 Mainboard interfering with neither ROM nor expansion connector.

DRAM and IDE controller are added using Amiga autoconfig mechanism with chain snooping. The expansion requires at least Kickstart 2.04 (at least v37.299).

## limitations
Due to the absense of Amiga Zorro Autoconfig signals **cfgin** and **cfgout** on the CPU slot, a snooping mechanism waits for all other devices to be configured first. The expansion configures last in the autoconfiguration chain and uses the remaining. All other expansions are configured
<!--stackedit_data:
eyJoaXN0b3J5IjpbLTE2MzM2MDQ4NTRdfQ==
-->