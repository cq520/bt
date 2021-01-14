#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
install_tmp='/tmp/bt_install.pl'
public_file=/www/server/panel/install/public.sh
if [ ! -f $public_file ];then
	wget -O $public_file http://download.bt.cn/install/public.sh -T 5;
fi
. $public_file
download_Url=$NODE_URL
pluginPath=/www/server/panel/plugin/btapp

Install_btapp()
{
	mypip="/www/server/panel/pyenv/bin/pip"
	if [ -f $mypip ];then
		$mypip install pycryptodome
	else
		pip install pycryptodome
	fi
	mkdir -p $pluginPath
	echo '正在安装脚本文件...' > $install_tmp
	wget -O $pluginPath/btapp_main.py $download_Url/install/plugin/btapp/btapp_main.py -T 5
	wget -O $pluginPath/index.html $download_Url/install/plugin/btapp/index.html -T 5
	wget -O $pluginPath/info.json $download_Url/install/plugin/btapp/info.json -T 5
	wget -O $pluginPath/icon.png $download_Url/install/plugin/btapp/icon.png -T 5
	wget -O $pluginPath/install.sh $download_Url/install/plugin/btapp/install.sh -T 5
	\cp -a -r /www/server/panel/plugin/btapp/icon.png /www/server/panel/BTPanel/static/img/soft_ico/ico-btapp.png
	echo '安装完成' > $install_tmp
}


Uninstall_btapp()
{
	rm -rf /www/server/panel/static/btapp
	rm -rf $pluginPath
}

if [ "${1}" == 'install' ];then
	Install_btapp
elif [ "${1}" == 'uninstall' ];then
	Uninstall_btapp
fi
