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

installBaseArch () {
    pacstrap /mnt base linux linux-firmware base-devel
    genfstab -U /mnt >> /mnt/etc/fstab
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
