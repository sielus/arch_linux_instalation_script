#!/bin/bash
installBaseArch () {
    pacstrap /mnt base linux linux-firmware base-devel
    genfstab -U /mnt >> /mnt/etc/fstab
    clear
}

prepareDisks () {
   mkfs.ext4 $1
   mount $1 /mnt 
   mkswap $2
   swapon $2
   clean
   lsblk /dev/$3
   installBaseArch
}

main () {
    echo "Welcom in beta MBR Arch linux instller!"
    echo "Choce disk to partition for Arch"
    lsblk
    read -p "Select disk for partitioning: " disk
    #cfdisk /dev/$disk
    clear
    echo "Your actual disk table : "
    lsblk /dev/$disk
    read -p "Select root partition: " rootPartition
    read -p "Select swap partition: " spawPartition
    #timedatectl set-ntp true

    read -p "Can we format partitions? (y / n): " formatPartitions

    if  [ "$formatPartitions" = "y" ] 
    then
        prepareDisks $rootPartition $spawPartition $disk
    else
        echo "Instalation aborded"
    fi

}

main
