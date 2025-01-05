# Install Arch Linux



I recently bought a mini PC because I wanted a lightweight machine that I can easily carry anywhere. Arch Linux's minimalistic, rolling-release approach aligns perfectly with my love for a Vim-based workflow and a highly customizable setup. While the process can seem intimidating at first, it’s an incredibly rewarding experience that offers complete control over your system.

---

# Installing Arch Linux (UEFI or BIOS)

Arch Linux is well-known for giving users full control over their system. This guide walks you through a fresh Arch Linux installation. While it is detailed, always refer to the [official Arch Wiki](https://wiki.archlinux.org/) for up-to-date information.

---

## Contents

1. [Prerequisites](#prerequisites)
2. [Creating a Bootable USB](#creating-a-bootable-usb)
3. [Initial Setup](#initial-setup)
    - [Check UEFI or BIOS](#check-uefi-or-bios)
    - [Wi-Fi Connection](#wi-fi-connection)
    - [Check Internet](#check-internet)
    - [Time & NTP](#time--ntp)
4. [Partitioning](#partitioning)
    - [Using `fdisk` or `cfdisk`](#using-fdisk-or-cfdisk)
    - [BIOS Partition Scheme](#bios-partition-scheme)
    - [UEFI Partition Scheme](#uefi-partition-scheme)
5. [Formatting and Mounting](#formatting-and-mounting)
    - [Creating File Systems](#creating-file-systems)
    - [Mounting Partitions](#mounting-partitions)
6. [Installing the Base System](#installing-the-base-system)
    - [Fast Mirror Selection](#fast-mirror-selection)
    - [`pacstrap` / `basestrap`](#pacstrap--basestrap)
    - [Generating `fstab`](#generating-fstab)
    - [Chroot](#chroot)
7. [Configuration](#configuration)
    - [Setting up Network Manager](#setting-up-network-manager)
    - [Installing and Configuring GRUB](#installing-and-configuring-grub)
    - [Root Password](#root-password)
    - [Locale and Timezone](#locale-and-timezone)
    - [Hostname](#hostname)
    - [Final Steps](#final-steps)
8. [Post-Installation](#post-installation)
    - [Creating a New User](#creating-a-new-user)
    - [Sudoers Configuration](#sudoers-configuration)
    - [Installing X.org and a Window Manager](#installing-xorg-and-a-window-manager)
    - [Fonts](#fonts)
    - [Enabling a Display Manager (Optional)](#enabling-a-display-manager-optional)
    - [Sound Setup](#sound-setup)
    - [Installing Yay (AUR Helper)](#installing-yay-aur-helper)

---

## Prerequisites

- A working internet connection on another device (in case you need help or to follow the Arch Wiki).
- A USB drive of at least 2 GB capacity.
- Familiarity with the command line.

> **Important**: Installing Arch Linux involves formatting drives, which is destructive. Back up all important data before proceeding.

---

## Creating a Bootable USB

### On Linux

```bash
sudo dd if=<path-to-arch-iso> of=<path-to-usb> status=progress
```

- `if` = input file (the ISO file).
- `of` = output file (usually something like `/dev/sdb`).
- **Be sure to confirm** the correct USB path using `lsblk` or `fdisk -l` before running the command.

### On Windows

- Use [Rufus](https://rufus.ie/). It’s a straightforward tool that avoids many potential pitfalls.

---

## Initial Setup

1. **Boot from your USB** and select the Arch Linux USB in your system’s boot menu.
2. You should see a command-line shell once Arch boots.

### Check UEFI or BIOS

```bash
ls /sys/firmware/efi/efivars
```

- If you get an error, you’re in BIOS (Legacy) mode.
- If you see contents, you’re in UEFI mode.

### Wi-Fi Connection

If you’re on Wi-Fi, use `iwctl`:

```bash
iwctl
device list
station <wlan> scan
station <wlan> get-networks
station <wlan> connect <wifi-name>
station <wlan> show
exit
```

### Check Internet

```bash
ping google.com
```

If you have no connection, re-check your Wi-Fi settings or use a wired connection.

### Time & NTP

```bash
timedatectl set-ntp true
```

This ensures your system clock stays synchronized.

---

## Partitioning

### Using `fdisk` or `cfdisk`

1. Identify target disk: `lsblk`
2. Open the disk utility:
    
    ```bash
    fdisk /dev/sda
    ```
    
    or
    
    ```bash
    cfdisk /dev/sda
    ```
    

### BIOS Partition Scheme

A common layout might be:

- **Boot**: `+200M`
- **Swap**: typically 50% of your RAM size (`+8G` for 16 GB RAM)
- **Root**: at least `+25G`
- **Home**: rest of the disk space

Press `w` to write changes and exit.

### UEFI Partition Scheme

- **EFI**: around `+550M` and formatted as FAT32.
- **Swap**: 50% of RAM or as needed.
- **Root**: Minimum `+25G` or more.
- **Home**: Rest of the disk (if desired on a separate partition).

---

## Formatting and Mounting

### Creating File Systems

Example commands (adjust partitions to suit your layout):

```bash
mkfs.ext4 /dev/sda1       # For /boot or /root or /home
mkfs.fat -F32 /dev/sda1   # For UEFI partition if using UEFI
mkswap /dev/sda2          # Swap partition
```

### Mounting Partitions

1. **Swap**:
    
    ```bash
    swapon /dev/sda2
    ```
    
2. **Root**:
    
    ```bash
    mount /dev/sda3 /mnt
    ```
    
3. **Boot (UEFI)**:
    
    ```bash
    mkdir /mnt/boot
    mount /dev/sda1 /mnt/boot
    ```
    
4. **Home** (if separate):
    
    ```bash
    mkdir /mnt/home
    mount /dev/sda4 /mnt/home
    ```
    

---

## Installing the Base System

### Fast Mirror Selection

Choose the fastest mirrors by editing `/etc/pacman.d/mirrorlist`. Move the closest/fastest mirrors to the top. This significantly speeds up package downloads.

### `pacstrap` / `basestrap`

#### For Arch Linux:

```bash
pacstrap /mnt base base-devel linux linux-firmware vim git
```

#### For Artix Linux (example):

```bash
basestrap -i /mnt base base-devel runit elogind-runit linux linux-firmware \
  grub networkmanager networkmanager-runit cryptsetup lvm2 lvm2-runit neovim vim
```

### Generating `fstab`

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

Check the file to ensure correct entries:

```bash
vim /mnt/etc/fstab
```

### Chroot

Now “enter” the new system:

- **Arch**:
    
    ```bash
    arch-chroot /mnt
    ```
    
- **Artix**:
    
    ```bash
    artix-chroot /mnt bash
    ```
    

---

## Configuration

### Setting up Network Manager

```bash
pacman -S networkmanager
systemctl enable NetworkManager
```

_(In Artix, you would enable the corresponding runit service instead.)_

### Installing and Configuring GRUB

#### For BIOS

```bash
pacman -S grub
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
```

#### For UEFI

```bash
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg
```

### Root Password

```bash
passwd
```

Set a strong password for the root user.

### Locale and Timezone

1. Edit `/etc/locale.gen` and uncomment your locale lines (e.g., `en_US.UTF-8`).
    
2. Generate them:
    
    ```bash
    locale-gen
    ```
    
3. Create `/etc/locale.conf`:
    
    ```bash
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    ```
    
4. Set your timezone:
    
    ```bash
    ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
    # or use tzselect
    ```
    

### Hostname

```bash
echo "myhostname" > /etc/hostname
```

### Final Steps

Exit the chroot environment:

```bash
exit
umount -R /mnt
reboot
```

Remove your USB before booting, and the system should start from the newly installed Arch Linux.

---

## Post-Installation

### Creating a New User

1. Log in as `root`.
    
2. Create a user:
    
    ```bash
    useradd -m -g wheel <username>
    passwd han
    ```
    
3. Add additional groups if needed:
    
    ```bash
    usermod -aG audio,video,storage han
    ```
    

### Sudoers Configuration

Edit `/etc/sudoers`:

```bash
visudo
```

Add or uncomment a line to allow members of the wheel group to use `sudo`:

```text
%wheel ALL=(ALL:ALL) ALL
```

---

## Installing X.org and a Window Manager

1. **Install Xorg**:
    
    ```bash
    pacman -S xorg-server xorg-xinit
    ```
    
2. **Minimal Window Manager**:
    
    ```bash
    pacman -S i3 dmenu rxvt-unicode
    ```
    
3. **Start X** (for testing):
    
    ```bash
    startx
    ```
    
4. For an automated start, add `exec i3` in your `~/.xinitrc`.

---

## Fonts

```bash
sudo pacman -S noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra
```

Or any other font packages that suit your language preferences. For powerline or devicons, install Nerd Fonts:

```bash
yay -S nerd-fonts-hack
```

---

## Enabling a Display Manager (Optional)

If you prefer a graphical login screen:

```bash
sudo pacman -S lightdm lightdm-gtk-greeter
sudo systemctl enable lightdm.service
```

_(Again, adapt for runit or other init systems.)_

---

## Sound Setup

### Alsa

```bash
sudo pacman -S alsa-utils alsa-plugins
amixer
```

- Use `M` to unmute any channels.

### PulseAudio

```bash
sudo pacman -S pulseaudio pulsemixer
pulseaudio --start
```

---

## Installing Yay (AUR Helper)

1. Clone the Yay repository:
    
    ```bash
    git clone https://aur.archlinux.org/yay.git
    ```
    
2. Build and install:
    
    ```bash
    cd yay
    makepkg -si
    ```
    

Yay lets you install packages from both the official repositories and the AUR.

---

## Conclusion

Congratulations! Your Arch Linux system is now up and running. From here, you can customize it with whatever software and configurations you like. Remember, the [Arch Wiki](https://wiki.archlinux.org/) is your best friend for finding detailed guides and troubleshooting tips.

Happy hacking!

