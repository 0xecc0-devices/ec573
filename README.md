# ec573 - Amiga 500 8MB Z2 DRAM + 2 channel IDE controller

## description
The ecc0 573 - or ec573 - is an Amiga 500 internal 8MB DRAM Zorro II expansion with 2 channel autoboot IDE controller sitting under the MC68000 CPU. It does fit into a standard Amiga 500 Mainboard interfering with neither ROM nor expansion connector.

### rendered pcb
![rendered ec573 v1.0 pcb](https://github.com/0xecc0-devices/ec573/blob/main/images/ec573.png)

### real pcb
![real hardware ec573 v1.0](https://github.com/0xecc0-devices/ec573/blob/main/images/ec573_top.jpg)
### fitted into A500
![ec573 v1.0 fitted into A500](https://github.com/0xecc0-devices/ec573/blob/main/images/ec573_fitted.jpg)

DRAM and IDE controller are added using Amiga autoconfig mechanism with chain snooping. The expansion requires at least Kickstart 2.04 (v37.299).

## features

 - 8MB DRAM Zorro II memory expansion
  - IDE controller with 2 channels for 4 devices using the fabulous [lide.device](https://github.com/LIV2/lide.device)
 - full Zorro II autoconfig
 - jumperless
 - 2,5" IDE connector
 - 3,5" IDE connector with +5V power supply (fused on pin 20)
 - IDE LED connector
 - 128kB IDE controller ROM with CD boot capability
 - IDE autoboot ROM in circuit flash updateable
 - compatible with Kickstart v37.299 (2.04) and later

## technical details

 - 8MB DRAM mapped into Amiga's address space $20.0000 - $9F.FFFF
 - 128kB IDE controller mapped as I/O device into Amiga's address space in the range 0xE9.0000-$EF.FFFF

## limitations
The ecc0 573 has been designed to achieve several goals. This leaves the finished design with limitations which are intended, yet to be made transparent.

1. Due to the absense of Amiga Zorro Autoconfig signals **cfgin** and **cfgout** on the CPU slot, a snooping mechanism waits for all other devices to be configured first. This snooping mechanism needs at least Kickstart v37.299 to work.
2. Neither DRAM nor IDE controller are deactivateable.
3. The Zorro II DRAM size is fixed to 8MB. If another autoconfig device is claiming any memory before, none of the expansion's DRAM will be available.
4. The IDE controller uses [lide.device](https://github.com/LIV2/lide.device) by Matt Harlum as autoboot firmware thus inheriting all it's limitations.
5. The expansion always configures last in the autoconfiguration chain and uses the remaining resources available.
<!--stackedit_data:
eyJoaXN0b3J5IjpbLTc4MjQ0NTY3MiwxMDk5NTEyNDgxXX0=
-->