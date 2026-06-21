# ec573 - Amiga 500 8MB Z2 DRAM + 2 channel IDE controller

## Device description
The ecc0 573 - or ec573 - is an Amiga 500 internal 8MB DRAM Zorro II expansion with 2 channel autoboot IDE controller sitting under the MC68000 CPU. It does fit into a standard Amiga 500 Mainboard interfering with neither ROM nor expansion connector.

The expansion works withDRAM and IDE controller are added using Amiga autoconfig mechanism.



## limitations
Due to the absense of Amiga Zorro autoconfiguration signals on the CPU slot, an autoconfiguration snooping mechanism waits for all other autoconfig devices to be configured first. The expansion configures last in the autoconfiguration chain. All other expansions are configured
<!--stackedit_data:
eyJoaXN0b3J5IjpbLTE4NTYwMTY3NTFdfQ==
-->