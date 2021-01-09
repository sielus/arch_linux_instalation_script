#!/bin/bash

choseIntelOrAmd () {
    echo "CPU model" 
    lscpu | grep name
    read -p "CPU intel or amd? ( i / a ): " var

    if  [ "$var" = "i" ] 
    then
        pacman -Sy intel-ucode
    else
        pacman -Sy amd-ucode
    fi
    grub-mkconfig -o /boot/grub/grub.cfg

    clear
    echo "Installation complete"
}

installPackage () { 
    pacman -Sy networkmanager bash-completion network-manager-applet gvfs ntfs-3g git vlc steam mesa firefox aria2 gedit zip xarchiver a52dec faac faad2 flac jasper lame libdca libdv libmad libmpeg2 libtheora libvorbis libxv wavpack x264 xvidcore libreoffice-fresh ttf-hannom
    systemctl enable NetworkManager.service
    read -p "Install lightdm + xfce4? (y / n): " installXfce
    
    if  [ "$installXfce" = "y" ] 
    then
        pacman -Sy lightdm lightdm-gtk-greeter xfce4 xfce4-goodies
        systemctl enable lightdm.service
    fi
    pacman -Syyu -y
    clear
    choseIntelOrAmd
}

configPacman () {
    rm -r /mnt/etc/pacman.conf
    cp pacman.conf /mnt/etc/
}

configGrub () {
    grub-install --target=i386-pc /dev/$disk
    grub-mkconfig -o /boot/grub/grub.cfg
    installPackage
}

createUser () {
    echo "Enter root passwd"
    passwd
    read -p "Enter user login" login
    useradd -m -G wheel,storage,power -s /bin/bash $login
    echo "Eter $login passwd"
    passwd $login
    clean
    configGrub
}

createHostname () {
    read -p "Enter your hostname: " hostname
    echo $hostname > /etc/hostname
    clear
    createUser
}

selectLang () {
    read -p "Uncoment your language!"
    nano /etc/locale.gen
    locale-gen
    clean
    createHostname
}

selectRegion () {
    echo "Select your region"
    ls /usr/share/zoneinfo/
    read -p "Region: " region
    
    echo "Select your city"
    ls /usr/share/zoneinfo/$region/
    read -p "City: " city
    ln -sf /usr/share/zoneinfo/$region/$city /etc/localtime
    hwclock --systohc
    clean
    selectLang
}

generatePacmanConfig () {
    echo "#
    # /etc/pacman.conf
    #
    # See the pacman.conf(5) manpage for option and repository directives

    #
    # GENERAL OPTIONS
    #
    [options]
    # The following paths are commented out with their default values listed.
    # If you wish to use different paths, uncomment and update the paths.
    #RootDir     = /
    #DBPath      = /var/lib/pacman/
    #CacheDir    = /var/cache/pacman/pkg/
    #LogFile     = /var/log/pacman.log
    #GPGDir      = /etc/pacman.d/gnupg/
    #HookDir     = /etc/pacman.d/hooks/
    HoldPkg     = pacman glibc
    #XferCommand = /usr/bin/curl -L -C - -f -o %o %u
    #XferCommand = /usr/bin/wget --passive-ftp -c -O %o %u
    #CleanMethod = KeepInstalled
    Architecture = auto

    # Pacman won't upgrade packages listed in IgnorePkg and members of IgnoreGroup
    #IgnorePkg   =
    #IgnoreGroup =

    #NoUpgrade   =
    #NoExtract   =

    # Misc options
    #UseSyslog
    #Color
    #TotalDownload
    CheckSpace
    #VerbosePkgLists

    # By default, pacman accepts packages signed by keys that its local keyring
    # trusts (see pacman-key and its man page), as well as unsigned packages.
    SigLevel    = Required DatabaseOptional
    LocalFileSigLevel = Optional
    #RemoteFileSigLevel = Required

    # NOTE: You must run `pacman-key --init` before first using pacman; the local
    # keyring can then be populated with the keys of all official Arch Linux
    # packagers with `pacman-key --populate archlinux`.

    #
    # REPOSITORIES
    #   - can be defined here or included from another file
    #   - pacman will search repositories in the order defined here
    #   - local/custom mirrors can be added here or in separate files
    #   - repositories listed first will take precedence when packages
    #     have identical names, regardless of version number
    #   - URLs will have $repo replaced by the name of the current repo
    #   - URLs will have $arch replaced by the name of the architecture
    #
    # Repository entries are of the format:
    #       [repo-name]
    #       Server = ServerName
    #       Include = IncludePath
    #
    # The header [repo-name] is crucial - it must be present and
    # uncommented to enable the repo.
    #

    # The testing repositories are disabled by default. To enable, uncomment the
    # repo name header and Include lines. You can add preferred servers immediately
    # after the header, and they will be used before the default mirrors.

    #[testing]
    #Include = /etc/pacman.d/mirrorlist

    [core]
    Include = /etc/pacman.d/mirrorlist

    [extra]
    Include = /etc/pacman.d/mirrorlist

    #[community-testing]
    #Include = /etc/pacman.d/mirrorlist

    [community]
    Include = /etc/pacman.d/mirrorlist

    # If you want to run 32 bit applications on your x86_64 system,
    # enable the multilib repositories as required here.

    #[multilib-testing]
    #Include = /etc/pacman.d/mirrorlist

    [multilib]
    Include = /etc/pacman.d/mirrorlist

    # An example of a custom package repository.  See the pacman manpage for
    # tips on creating your own repositories.
    #[custom]
    #SigLevel = Optional TrustAll
    #Server = file:///home/custompkgs
    " > pacman.conf
}

installBaseArch () {
    pacstrap /mnt base linux linux-firmware base-devel
    genfstab -U /mnt >> /mnt/etc/fstab
    generatePacmanConfig 
    configPacman
    clear
    arch-chroot /mnt
    selectRegion
}

prepareDisks () {
   mkfs.ext4 /dev/$1
   mount /dev/$1 /mnt 
   mkswap /dev/$2
   swapon /dev/$2
   clean
   lsblk /dev/$3
   installBaseArch
}

main () {
    echo "Welcom in beta MBR Arch linux instller!"
    echo "Choce disk to partition for Arch"
    lsblk
    read -p "Select disk for partitioning: " disk
    cfdisk /dev/$disk
    clear
    echo "Your actual disk table : "
    lsblk /dev/$disk
    read -p "Select root partition: " rootPartition
    read -p "Select swap partition: " spawPartition
    timedatectl set-ntp true

    read -p "Can we format partitions? (y / n): " formatPartitions

    if  [ "$formatPartitions" = "y" ] 
    then
        prepareDisks $rootPartition $spawPartition $disk
    else
        echo "Installation aborded"
    fi
}

main
