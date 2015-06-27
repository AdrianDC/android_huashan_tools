#!/bin/bash
timestart=$(date +%s);
currentdir=$PWD;

# Configuration
filepath="$currentdir/..";
filename="boot.img";
filetarget="/media/sf_Desktop";
androidpath="/media/adriandc/UbuntuWork/Projects/Android";
githubfolder="$currentdir/../GitHub";
kernelbuilder="$currentdir/android_kernel_builder";
kernelrepository="https://github.com/AdrianDC/android_kernel_sony_msm8x60.git";
kernelbranch="cm-12.1";
kernelfolder="$githubfolder/android_kernel_sony_msm8x60";
zimagebuilt="$kernelfolder/arch/arm/boot/zImage";
zimagefile=$kernelbuilder/zImage
export ARCH=arm
export SUBARCH=arm
export CROSS_COMPILE="$androidpath/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi-"
export KBUILD_BUILD_USER="AdrianDC"
export KBUILD_BUILD_HOST="KernelBuild"

# Delete the target files
if [ -f $zimagefile ]; then rm -f $zimagefile; fi;
if [ -f $filepath/$filename ]; then rm -f $filepath/$filename; fi;
if [ -f $filetarget/$filename ]; then rm -f $filetarget/$filename; fi;

# Update the sources
echo "";
echo " [ Updating the sources ]";
echo "";
if [ -d $kernelfolder ]; then
  cd $kernelfolder/;
  git remote rm origin >/dev/null >/dev/null 2>&1;
  git remote add origin $kernelrepository;
  git fetch origin $kernelbranch;
  git reset --hard FETCH_HEAD;
else
  cd $githubfolder;
  git clone $kernelrepository;
  cd $kernelfolder/;
fi;

# Make the kernel zImage
echo "";
echo " [ Making the kernel zImage ]";
echo "";
#make mrproper clean;
make cm_viskan_huashan_defconfig;
make -j8;
if ! [ -a $zimagebuilt ]; then
  echo "";
  echo "  Kernel Compilation failed.";
  echo "";
  read key;
  exit 1;
else
  cp $zimagebuilt $zimagefile;
fi;

# Make the kernel boot.img
echo "";
echo " [ Make the kernel boot.img ]";
echo "";
cd $kernelbuilder/;
if [ -f ./boot.elf ]; then rm ./boot.elf; fi;
if [ -f ./boot.img ]; then rm ./boot.img; fi;
python ./mkelf.py -o boot.elf zImage@0x80208000 ramdisk.img@0x81900000,ramdisk RPM.bin@0x00020000,rpm cmdline.txt@0x00000000,cmdline;
mv ./boot.elf $filepath/$filename;
echo "  \"fastboot flash boot $filename & fastboot reboot\"";
echo "";

# Final target
if [ ! -z "$filetarget" ]; then
  cp $filepath/$filename /media/sf_Desktop/$filename;
fi;

# End of build
timediff=$(($(date +%s)-$timestart));
echo "";
echo " [ Done in $timediff secs ]";
echo "";
read key;

