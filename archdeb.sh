#!/bin/sh
zenity --notification --text="[archdeb]开始安装$1"
if [ -z "$1" ]; then
    input_file="$(zenity --file-selection --file-filter='Debian Packages (*.deb) | *.deb' --title=请选择要安装的deb文件)"
else
    input_file="$1"
fi
if [ -z "$input_file" ]; then
    exit 1
fi
if [ ! -e "$input_file" ]; then
    echo "文件不存在!"
    zenity --error --text="文件不存在!"
    exit 1
fi
if [ ! "${input_file: -4}" == ".deb" ]; then
    echo "文件并不是.deb类型!"
    zenity --error --text="文件并不是.deb类型!"
    exit 1
fi
input_file=$(realpath "$input_file")
echo "$input_file"
rm -r "/tmp/${input_file##*/}_archdeb"
mkdir "/tmp/${input_file##*/}_archdeb" || exit 1
cd "/tmp/${input_file##*/}_archdeb" || exit 1
cp "$input_file" ./

debtap_output=$(debtap -Q $(realpath ./*.deb) 2>&1 | zenity --progress --title="[archdeb]生成安装包" --text="debtap正在生成安装包..." --auto-close --auto-kill --pulsate)
debtap_status=$?
echo "$debtap_status"
if [ ! $debtap_status -eq 0 ]; then
    echo "debtap命令执行失败!"
    echo "$debtap_output"
    zenity --notification --text="[archdeb]debtap命令执行失败!\n原因:$debtap_output"
    exit 1
fi
echo "debtap命令执行成功!"
ls -alh
folder=$(pwd)
output_file=$(ls -t *.pkg.tar.zst | head -n 1)
file_path=$(readlink -f "$folder/$output_file")
echo "准备安装生成的包!"
echo "输出文件:$file_path"
zenity --notification --text="[archdeb]debtap成功生成安装包:$file_path,开始安装..."
konsole -e "sudo pacman -U $file_path"
zenity --notification --text="[archdeb]文件$1安装完成,开始删除生成的文件夹${input_file##*/}_archdeb"
echo "删除文件..."
cd ..
rm -rf $folder

