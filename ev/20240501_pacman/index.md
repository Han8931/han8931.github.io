# Handy Pacman Commands in Arch Linux


[Pacman](https://archlinux.org/pacman/), the package manager for Arch Linux, is known for its **simple** binary package format and **easy-to-use** [build system](https://wiki.archlinux.org/title/Arch_build_system "Arch build system"). The primary aim of Pacman is to facilitate straightforward management of packages from both the [official repositories](https://wiki.archlinux.org/title/Official_repositories "Official repositories") and user-generated builds.

Pacman ensures your system remains updated by synchronizing the package lists with the master server. This client/server model simplifies the process of downloading and installing packages, along with all their dependencies, using basic commands.

### Installing and Upgrading Packages
- **Install a Package:**
  ```bash
  sudo pacman -S <package-name>
  ```

- **Full System Upgrade:**
  ```bash
  sudo pacman -Syu
  ```
  - `-y` synchronizes the database, similar to `sudo apt-get update`.
  - `-u` upgrades all out-of-date packages, akin to `sudo apt-get upgrade`.

- **Installing Packages from Git:**
  Clone the package and install:
  ```bash
  git clone <repository-url>
  makepkg -si
  ```

### Removing Packages
- **Remove a Specific Package:**
  ```bash
  sudo pacman -R <package-name>
  ```
  Using `-s` removes dependencies not required by other packages, but be cautious as it may affect dependencies needed by other programs.

- **Best Practice for Removing Packages:**
  ```bash
  sudo pacman -Rns <package-name>
  ```

- **Remove Obsolete Packages:**
  ```bash
  sudo pacman -Sc
  ```

### Managing Package Lists
- **List All Installed Packages:**
  ```bash
  sudo pacman -Q
  ```

- **List Manually Installed Packages:**
  ```bash
  sudo pacman -Qe
  ```

- **List Installed AUR Packages:**
  ```bash
  sudo pacman -Qm
  ```

- **List Unneeded Dependencies:**
  ```bash
  sudo pacman -Qdt
  ```

## Getting Started with Pacman

- **Creating a List of Installed Packages:**
  Generate a list to easily reinstall packages on a new system:
  ```bash
  pacman -Qqen > pkglist.txt
  ```

  To reinstall packages from the list:
  ```bash
  pacman -S - < pkglist.txt
  ```


### Rollback to Previous Versions
- **List Cached Packages:**
  ```bash
  ls /var/cache/pacman/pkg/
  ```

  To downgrade a package:
  ```bash
  sudo pacman -U <package-file>
  ```

### Managing Mirror Lists
- **Edit and Refresh Mirror List:**
  ```bash
  sudo vim /etc/pacman.d/mirrorlist
  sudo pacman -Syy
  ```
  Use `-yy` to force a refresh of the package databases, even if they are up to date.


### Configuration Tips
- **Enable Parallel Downloads:**
  Open your configuration file:
  ```bash
  sudo vim /etc/pacman.conf
  ```
  Then uncomment or add the following line to enable multiple simultaneous downloads:
  ```
  ParallelDownloads=5
  ```
- **Ignore Specific Packages:**
  Add the following line to `/etc/pacman.conf` to prevent specific packages from being updated:
  ```bash
  IgnorePkg = postgresql*
  ```



