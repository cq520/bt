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
pluginPath=/www/server/panel/plugin/java_manager

Install_webservice()
{
	mkdir -p $pluginPath
	echo '正在安装脚本文件...' > $install_tmp
	 
	wget -O $pluginPath/java_manager_main.py $download_Url/install/plugin/java_manager/java_manager_main.py -T 5
	wget -O $pluginPath/public_check.py $download_Url/install/plugin/java_manager/public_check.py -T 5
	wget -O $pluginPath/springboot_manager.py $download_Url/install/plugin/java_manager/springboot_manager.py -T 5
	wget -O $pluginPath/tomcat_manager.py $download_Url/install/plugin/java_manager/tomcat_manager.py -T 5
	wget -O $pluginPath/index.html $download_Url/install/plugin/java_manager/index.html -T 5
	wget -O $pluginPath/info.json $download_Url/install/plugin/java_manager/info.json -T 5
	wget -O $pluginPath/icon.png $download_Url/install/plugin/java_manager/icon.png -T 5
	  
	echo '安装完成' > $install_tmp
}

Uninstall_webservice()
{
	rm -rf $pluginPath
}

if [ "${1}" == 'install' ];then
	Install_webservice
elif  [ "${1}" == 'update' ];then
	Install_webservice
elif [ "${1}" == 'uninstall' ];then
	Uninstall_webservice
fi
