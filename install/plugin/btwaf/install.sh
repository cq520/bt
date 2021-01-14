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
pluginPath=/www/server/panel/plugin/btwaf

pyVersion=$(python -c 'import sys;print(sys.version_info[0]);')
py_zi=$(python -c 'import sys;print(sys.version_info[1]);')
pluginPath2=/www/server/panel/plugin/webshell_san
aacher=$(uname -a |grep -Po aarch64|awk 'NR==1')
Centos6Check=$(cat /etc/redhat-release|grep ' 6.'|grep -i centos)


Install_LuaJIT()
{	
	LUAJIT_VER="2.1.0-beta3"
	LUAJIT_INC_PATH="luajit-2.1"
	if [ ! -f '/usr/local/lib/libluajit-5.1.so' ] || [ ! -f "/usr/local/include/${LUAJIT_INC_PATH}/luajit.h" ];then
		wget -c -O LuaJIT-${LUAJIT_VER}.tar.gz ${download_Url}/install/src/LuaJIT-${LUAJIT_VER}.tar.gz -T 10
		tar xvf LuaJIT-${LUAJIT_VER}.tar.gz
		cd LuaJIT-${LUAJIT_VER}
		make linux
		make install
		cd ..
		rm -rf LuaJIT-*
		export LUAJIT_LIB=/usr/local/lib
		export LUAJIT_INC=/usr/local/include/${LUAJIT_INC_PATH}/
		ln -sf /usr/local/lib/libluajit-5.1.so.2 /usr/local/lib64/libluajit-5.1.so.2
		echo "/usr/local/lib" >> /etc/ld.so.conf
		ldconfig
	fi
}

Install_white_ip()
{
cat >$pluginPath/white.py<< EOF
# coding: utf-8
import sys
sys.path.append('/www/server/panel/class')
import public, json
def ip2long(ip):
    ips = ip.split('.')
    if len(ips) != 4: return 0
    iplong = 2 ** 24 * int(ips[0]) + 2 ** 16 * int(ips[1]) + 2 ** 8 * int(ips[2]) + int(ips[3])
    return iplong
def zhuanhuang(aaa):
    ac = []
    cccc = 0
    list = []
    list2 = []
    for i in range(len(aaa)):
        for i2 in aaa[i]:
            dd = ''
            coun = 0
            for i3 in i2:
                if coun == 3:
                    dd += str(i3)
                else:
                    dd += str(i3) + '.'
                coun += 1
            list.append(ip2long(dd))
            cccc += 1
            if cccc % 2 == 0:
                aa = []
                bb = []
                aa.append(list[0])
                bb.append(list[1])
                cc = []
                cc.append(aa)
                cc.append(bb)
                ac.append(list)
                list = []
                list2 = []
    return ac
def main():
    try:
        aaa = json.loads(public.ReadFile("/www/server/btwaf/rule/ip_white.json"))
        if not aaa:return  False
        if type(aaa[0][0])==list:
            f = open('/www/server/btwaf/rule/ip_white.json', 'w')
            f.write(json.dumps(zhuanhuang(aaa)))
            f.close()
    except:
        public.writeFile("/www/server/btwaf/rule/ip_white.json", json.dumps([]))

    try:
        aaa = json.loads(public.ReadFile("/www/server/btwaf/rule/ip_black.json"))
        if not aaa: return False
        if type(aaa[0][0]) == list:
            f = open('/www/server/btwaf/rule/ip_black.json', 'w')
            f.write(json.dumps(zhuanhuang(aaa)))
            f.close()
    except:
        public.writeFile("/www/server/btwaf/rule/ip_black.json", json.dumps([]))
main()
print("转换ip格式")
EOF
}



Install_btwaf()
{ 
	usranso2=`ls -l /usr/local/lib/lua/5.1/cjson.so | awk '{print $5}'`
	if [ $usranso2 -eq 0 ];then
		rm -rf /usr/local/lib/lua/5.1/cjson.so
	fi
	rm -rf /www/server/panel/vhost/nginx/free_waf.conf
	rm -rf /www/server/free_waf
	rm -rf /www/server/panel/plugin/free_waf
	Install_cjson
	#Install_socket
	mkdir $pluginPath2
	mkdir -p $pluginPath
	wget -O $pluginPath/firewalls_list.py http://download.bt.cn/btwaf_rule/test/btwaf/firewalls_list.py -T 5
	yum install lua-socket -y
	yum install lua-json -y 
	apt-get install lua-socket -y
	apt-get install lua-cjson -y
	echo '正在安装脚本文件...' > $install_tmp
	if [ "$aacher" == "aarch64" ];then 
		if [  -f /www/server/panel/pyenv/bin/python ];then
			wget -O $pluginPath/btwaf_main.cpython-37m-aarch64-linux-gnu.zip $download_Url/btwaf_rule/test/btwaf/aachar64/btwaf_main.cpython-37m-aarch64-linux-gnu.zip -T 5
			unzip -o $pluginPath/btwaf_main.cpython-37m-aarch64-linux-gnu.zip -d $pluginPath > /dev/null
			rm -rf $pluginPath/btwaf_main.cpython-37m-aarch64-linux-gnu.zip
		else
			if [ "$pyVersion" == 2 ];then
				wget -O $pluginPath/btwaf_main.zip $download_Url/btwaf_rule/test/btwaf/aachar64/btwaf_main.zip -T 5
				unzip -o $pluginPath/btwaf_main.zip -d $pluginPath > /dev/null
				rm -rf $pluginPath/btwaf_main.zip
			else
				if [ "$py_zi" == 6 ];then 
					wget -O $pluginPath/btwaf_main.cpython-36m-aarch64-linux-gnu.zip $download_Url/btwaf_rule/test/btwaf/aachar64/btwaf_main.cpython-36m-aarch64-linux-gnu.zip -T 5
					unzip -o $pluginPath/btwaf_main.cpython-36m-aarch64-linux-gnu.zip -d $pluginPath > /dev/null
					rm -rf $pluginPath/btwaf_main.cpython-36m-aarch64-linux-gnu.zip
				fi 
				if [ "$py_zi" == 7 ];then 
					wget -O $pluginPath/btwaf_main.cpython-37m-aarch64-linux-gnu.zip $download_Url/btwaf_rule/test/btwaf/aachar64/btwaf_main.cpython-37m-aarch64-linux-gnu.zip -T 5
					unzip -o $pluginPath/btwaf_main.cpython-37m-aarch64-linux-gnu.zip -d $pluginPath > /dev/null
					rm -rf $pluginPath/btwaf_main.cpython-37m-aarch64-linux-gnu.zip
				fi
			fi
		fi	
	else
		if [  -f /www/server/panel/pyenv/bin/python ];then
			wget -O $pluginPath/btwaf_main.cpython-37m-x86_64-linux-gnu.zip $download_Url/btwaf_rule/test/btwaf/8.7.1/btwaf_main.cpython-37m-x86_64-linux-gnu.zip -T 5
			unzip -o $pluginPath/btwaf_main.cpython-37m-x86_64-linux-gnu.zip -d $pluginPath > /dev/null
			rm -rf $pluginPath/btwaf_main.cpython-37m-x86_64-linux-gnu.zip
		else
			if [ "$pyVersion" == 2 ];then
				wget -O $pluginPath/btwaf_main.zip $download_Url/btwaf_rule/test/btwaf/8.7.1/btwaf_main.zip -T 5
				unzip -o $pluginPath/btwaf_main.zip -d $pluginPath > /dev/null
				rm -rf $pluginPath/btwaf_main.zip
			else
				if [ "$py_zi" == 6 ];then 
					wget -O $pluginPath/btwaf_main.cpython-36m-x86_64-linux-gnu.zip $download_Url/btwaf_rule/test/btwaf/8.7.1/btwaf_main.cpython-36m-x86_64-linux-gnu.zip -T 5
					unzip -o $pluginPath/btwaf_main.cpython-36m-x86_64-linux-gnu.zip -d $pluginPath > /dev/null
					rm -rf $pluginPath/btwaf_main.cpython-36m-x86_64-linux-gnu.zip
				fi 
				if [ "$py_zi" == 4 ];then 
					wget -O $pluginPath/btwaf_main.cpython-34m.zip $download_Url/btwaf_rule/test/btwaf/btwaf_main.cpython-34m.zip -T 5
					unzip -o $pluginPath/btwaf_main.cpython-34m.zip -d $pluginPath > /dev/null
					rm -rf $pluginPath/btwaf_main.cpython-34m.zip
				fi
				if [ "$py_zi" == 7 ];then 
					wget -O $pluginPath/btwaf_main.cpython-37m-x86_64-linux-gnu.zip $download_Url/btwaf_rule/test/btwaf/8.7.1/btwaf_main.cpython-37m-x86_64-linux-gnu.zip -T 5
					unzip -o $pluginPath/btwaf_main.cpython-37m-x86_64-linux-gnu.zip -d $pluginPath > /dev/null
					rm -rf $pluginPath/btwaf_main.cpython-37m-x86_64-linux-gnu.zip
				fi
			fi
		fi
	fi
	wget -O $pluginPath/btwaf_main.zip $download_Url/btwaf_rule/test/btwaf/8.7.1/btwaf_main.zip -T 5
	unzip -o $pluginPath/btwaf_main.zip -d $pluginPath > /dev/null
	rm -rf $pluginPath/btwaf_main.zip
	wget -O $pluginPath/webshell_check.py $download_Url/btwaf_rule/test/btwaf/webshell_check.py -T 5
	wget -O $pluginPath/btwaf_main.py $download_Url/btwaf_rule/test/btwaf/btwaf_main.py -T 5
	wget -O $pluginPath/send_vilidate.py $download_Url/btwaf_rule/test/btwaf/send_vilidate.py -T 5
	#wget -O $pluginPath/white.py $download_Url/btwaf_rule/test/btwaf/8.7.1/white.py -T 5
	Install_white_ip
	python $pluginPath/send_vilidate.py
	if [ ! -f /www/server/btwaf/captcha/num2.json ];then
		wget -O /www/server/btwaf/captcha.zip $download_Url/btwaf_rule/test/btwaf/captcha.zip -T 5
		unzip -o /www/server/btwaf/captcha.zip  -d /www/server/btwaf/ > /dev/null
		rm -rf /www/server/btwaf/captcha.zip
	fi
	wget -O $pluginPath/firewalls_list.py $download_Url/btwaf_rule/test/btwaf/firewalls_list.py -T 5
	wget -O $pluginPath/index.html $download_Url/btwaf_rule/test/btwaf/8.7.1/index.html -T 5
	wget -O $pluginPath/info.json $download_Url/btwaf_rule/test/btwaf/info.json -T 5
	wget -O $pluginPath/icon.png $download_Url/btwaf_rule/test/btwaf/icon.png -T 5
	wget -O $pluginPath/rule.json $download_Url/btwaf_rule/test/btwaf/rule.json -T 5
	if [ ! -f /www/server/panel/vhost/nginx/speed.conf ];then
		wget -O /www/server/panel/vhost/nginx/btwaf.conf $download_Url/btwaf_rule/test/btwaf/btwaf.conf -T 5
	else
		wget -O /www/server/panel/vhost/nginx/btwaf.conf $download_Url/btwaf_rule/test/btwaf/btwaf2.conf -T 5
	fi
	
	wget -O $pluginPath2/webshell_san_main.py $download_Url/btwaf_rule/test/btwaf/webshell_san_main.py -T 5
	\cp -a -r /www/server/panel/plugin/btwaf/icon.png /www/server/panel/static/img/soft_ico/ico-btwaf.png
	wget -O $pluginPath/btwaf.zip $download_Url/btwaf_rule/test/btwaf/btwaf.zip -T 5
	unzip -o $pluginPath/btwaf.zip -d /tmp/ > /dev/null
	rm -f $pluginPath/btwaf.zip
	btwaf_path=/www/server/btwaf
	mkdir -p $btwaf_path/html
	rm -rf /www/server/btwaf/cms
	mv /tmp/btwaf/cms/  $btwaf_path
	
	if [ ! -f $btwaf_path/html/get.html ];then
		\cp -a -r /tmp/btwaf/html/get.html $btwaf_path/html/get.html
		\cp -a -r /tmp/btwaf/html/get.html $btwaf_path/html/post.html
		\cp -a -r /tmp/btwaf/html/get.html $btwaf_path/html/cookie.html
		\cp -a -r /tmp/btwaf/html/get.html $btwaf_path/html/user_agent.html
		\cp -a -r /tmp/btwaf/html/get.html $btwaf_path/html/other.html
	fi
	mkdir -p $btwaf_path/rule
	\cp -a -r /tmp/btwaf/rule/cn.json $btwaf_path/rule/cn.json
	\cp -a -r /tmp/btwaf/rule/lan.json $btwaf_path/rule/lan.json

	if [ ! -f $btwaf_path/rule/post.json ];then
		\cp -a -r /tmp/btwaf/rule/url.json $btwaf_path/rule/url.json
		\cp -a -r /tmp/btwaf/rule/args.json $btwaf_path/rule/args.json
		\cp -a -r /tmp/btwaf/rule/post.json $btwaf_path/rule/post.json
		\cp -a -r /tmp/btwaf/rule/cookie.json $btwaf_path/rule/cookie.json
		\cp -a -r /tmp/btwaf/rule/head_white.json $btwaf_path/rule/head_white.json
		\cp -a -r /tmp/btwaf/rule/user_agent.json $btwaf_path/rule/user_agent.json
		\cp -a -r /tmp/btwaf/rule/cn.json $btwaf_path/rule/cn.json
		\cp -a -r /tmp/btwaf/rule/ip_white.json $btwaf_path/rule/ip_white.json
		\cp -a -r /tmp/btwaf/rule/scan_black.json $btwaf_path/rule/scan_black.json
		\cp -a -r /tmp/btwaf/rule/url_black.json $btwaf_path/rule/url_black.json
		\cp -a -r /tmp/btwaf/rule/ip_black.json $btwaf_path/rule/ip_black.json
		\cp -a -r /tmp/btwaf/rule/url_white.json $btwaf_path/rule/url_white.json
		\cp -a -r /tmp/btwaf/1.json $btwaf_path/1.json
		\cp -a -r /tmp/btwaf/2.json $btwaf_path/2.json
		\cp -a -r /tmp/btwaf/3.json $btwaf_path/3.json
		\cp -a -r /tmp/btwaf/4.json $btwaf_path/4.json
		\cp -a -r /tmp/btwaf/5.json $btwaf_path/5.json
		\cp -a -r /tmp/btwaf/6.json $btwaf_path/6.json
		\cp -a -r /tmp/btwaf/zhi.json $btwaf_path/zhi.json
	fi
	
	if [ ! -f $btwaf_path/webshell.json ];then
		\cp -a -r /tmp/btwaf/webshell.json $btwaf_path/webshell.json
	fi
	
	if [ ! -f $btwaf_path/webshell_url.json ];then
		\cp -a -r /tmp/btwaf/webshell_url.json $btwaf_path/webshell_url.json
	fi
	
	if [ ! -f $btwaf_path/shell_check.json ];then
		\cp -a -r /tmp/btwaf/shell_check.json $btwaf_path/shell_check.json
	fi
	
	if [ ! -f $btwaf_path/rule/cc_uri_white.json ];then
		\cp -a -r /tmp/btwaf/rule/cc_uri_white.json $btwaf_path/rule/cc_uri_white.json
	fi
	
	if [ ! -f /dev/shm/stop_ip.json ];then
		\cp -a -r /tmp/btwaf/stop_ip.json /dev/shm/stop_ip.json
	fi
	chmod 777 /dev/shm/stop_ip.json
	chown www:www /dev/shm/stop_ip.json
	
	
	if [ ! -f $btwaf_path/site.json ];then
		\cp -a -r /tmp/btwaf/site.json $btwaf_path/site.json
	fi
	
	if [ ! -f $btwaf_path/config.json ];then
		\cp -a -r /tmp/btwaf/config.json $btwaf_path/config.json
	fi
	
	if [ ! -f $btwaf_path/domains.json ];then
		\cp -a -r /tmp/btwaf/domains.json $btwaf_path/domains.json
	fi
	
	if [ ! -f $btwaf_path/total.json ];then
		\cp -a -r /tmp/btwaf/total.json $btwaf_path/total.json
	fi
	
	if [ ! -f $btwaf_path/drop_ip.log ];then
		
		\cp -a -r /tmp/btwaf/drop_ip.log $btwaf_path/drop_ip.log
	fi
	if [ ! -b /www/server/btwaf/captcha/num2.json ];then
		\cp -a -r /tmp/btwaf/10.55.lua $btwaf_path/init.lua
		
	else 
		\cp -a -r /tmp/btwaf/8.8.lua $btwaf_path/init.lua
	fi
	\cp -a -r /tmp/btwaf/libinjection.lua $btwaf_path/libinjection.lua
	
	\cp -a -r /tmp/btwaf/multipart.lua $btwaf_path/multipart.lua
	if [ ! -n "$Centos6Check" ]; then
		\cp -a -r /tmp/btwaf/libinjection_2020_09_14.so $btwaf_path/libinjection.so
	else
		\cp -a -r /tmp/btwaf/centos6_libinjection.so $btwaf_path/libinjection.so
	fi
	\cp -a -r /tmp/btwaf/ffijson.lua $btwaf_path/ffijson.lua
	\cp -a -r /tmp/btwaf/dns.lua $btwaf_path/dns.lua
	\cp -a -r /tmp/btwaf/body_lua2.lua $btwaf_path/body.lua
	\cp -a -r /tmp/btwaf/waf.lua $btwaf_path/waf.lua
	chmod +x $btwaf_path/waf.lua
	chmod +x $btwaf_path/init.lua
	mkdir -p /www/wwwlogs/btwaf
	chmod 777 /www/wwwlogs/btwaf
	chmod -R 755 /www/server/btwaf
	chmod -R 644 /www/server/btwaf/rule
	chmod -R 666 /www/server/btwaf/total.json
	chmod -R 666 /www/server/btwaf/drop_ip.log
	echo '' > /www/server/nginx/conf/luawaf.conf
	chown -R root:root /www/server/btwaf/
	chown www:www /www/server/btwaf/*.json
	chown www:www /www/server/btwaf/drop_ip.log
	
	/usr/bin/python $pluginPath/white.py
	python $pluginPath/white.py
	btpython $pluginPath/white.py
	
	/etc/init.d/nginx restart
	para1=$(ps -aux |grep nginx |grep  /www/server/nginx/conf/nginx.conf | awk 'NR==2')
	parc2=$(netstat -nltp|grep nginx| grep 80|wc -l)
	if [ ! -n "$para1" ]; then 
		if [ $parc2 -eq 0 ]; then 
			rm -rf /www/server/btwaf/init.lua
			Install_LuaJIT
			\cp -a -r /tmp/btwaf/test8.lua $btwaf_path/init.lua
			/etc/init.d/nginx restart
			para1=$(ps -aux |grep nginx |grep  /www/server/nginx/conf/nginx.conf | awk 'NR==2')
			parc2=$(netstat -nltp|grep nginx| grep 80|wc -l)
			if [ ! -n "$para1" ]; then 
				if [ $parc2 -eq 0 ]; then 
					cp -a -r /tmp/btwaf/xiu33.lua $btwaf_path/init.lua
					/etc/init.d/nginx restart
				fi
			fi
		fi
	fi
	chmod -R 755 /www/server/phpmyadmin/
	chown -R root:root /www/server/phpmyadmin/
	rm -rf /tmp/btwaf
	bash /www/server/panel/init.sh start
	echo > /www/server/panel/data/restart.pl
	echo '安装完成' > $install_tmp
}

Upload_btwaf()
{ 
	mkdir $pluginPath2
	wget -O $pluginPath/firewalls_list.py http://download.bt.cn/btwaf_rule/test/btwaf/firewalls_list.py -T 5
	echo '正在安装脚本文件...' > $install_tmp
	if [ "$pyVersion" == 2 ];then
		wget -O $pluginPath/btwaf_main.zip $download_Url/btwaf_rule/test/btwaf/btwaf_main.zip -T 5
		unzip -o $pluginPath/btwaf_main.zip -d $pluginPath > /dev/null
		rm -rf $pluginPath/btwaf_main.zip
	else
		wget -O $pluginPath/btwaf_main.cpython-34m.zip $download_Url/btwaf_rule/test/btwaf/btwaf_main.cpython-34m.zip -T 5
		unzip -o $pluginPath/btwaf_main.cpython-34m.zip -d $pluginPath > /dev/null
		rm -rf $pluginPath/btwaf_main.cpython-34m.zip
		wget -O $pluginPath/btwaf_main.cpython-36m-x86_64-linux-gnu.zip $download_Url/btwaf_rule/test/btwaf/btwaf_main.cpython-36m-x86_64-linux-gnu.zip -T 5
		unzip -o $pluginPath/btwaf_main.cpython-36m-x86_64-linux-gnu.zip -d $pluginPath > /dev/null
		rm -rf $pluginPath/btwaf_main.cpython-36m-x86_64-linux-gnu.zip
	fi
	wget -O $pluginPath/rule.json $download_Url/btwaf_rule/test/btwaf/rule.json -T 5
	wget -O $pluginPath/send_vilidate.py $download_Url/btwaf_rule/test/btwaf/send_vilidate.py -T 5
	python $pluginPath/send_vilidate.py
	wget -O $pluginPath2/webshell_san_main.py $download_Url/btwaf_rule/test/btwaf/webshell_san_main.py -T 5
	wget -O $pluginPath/btwaf_main.py $download_Url/btwaf_rule/test/btwaf/btwaf_main.py -T 5
	wget -O $pluginPath/firewalls_list.py $download_Url/btwaf_rule/test/btwaf/firewalls_list.py -T 5
	wget -O $pluginPath/index.html $download_Url/btwaf_rule/test/btwaf/index.html -T 5
	wget -O $pluginPath/info.json $download_Url/btwaf_rule/test/btwaf/info.json -T 5
	wget -O $pluginPath/icon.png $download_Url/btwaf_rule/test/btwaf/icon.png -T 5
	wget -O /www/server/panel/vhost/nginx/btwaf.conf $download_Url/btwaf_rule/test/btwaf/btwaf.conf -T 5
	\cp -a -r /www/server/panel/plugin/btwaf/icon.png /www/server/panel/static/img/soft_ico/ico-btwaf.png
	wget -O $pluginPath/btwaf.zip $download_Url/btwaf_rule/test/btwaf/btwaf.zip -T 5
	unzip -o $pluginPath/btwaf.zip -d /tmp/ > /dev/null
	rm -f $pluginPath/btwaf.zip
	mkdir -p $btwaf_path/rule
	btwaf_path=/www/server/btwaf
	mkdir -p $btwaf_path/html
	rm -rf /www/server/btwaf/cms
	mv /tmp/btwaf/cms/  $btwaf_path
	
	if [ ! -f $btwaf_path/html/get.html ];then
		\cp -a -r /tmp/btwaf/html/get.html $btwaf_path/html/get.html
		\cp -a -r /tmp/btwaf/html/get.html $btwaf_path/html/post.html
		\cp -a -r /tmp/btwaf/html/get.html $btwaf_path/html/cookie.html
		\cp -a -r /tmp/btwaf/html/get.html $btwaf_path/html/user_agent.html
		\cp -a -r /tmp/btwaf/html/get.html $btwaf_path/html/other.html
	fi

	if [ ! -f $btwaf_path/rule/url.json ];then
		\cp -a -r /tmp/btwaf/rule/url.json $btwaf_path/rule/url.json
		\cp -a -r /tmp/btwaf/rule/args.json $btwaf_path/rule/args.json
		\cp -a -r /tmp/btwaf/rule/post.json $btwaf_path/rule/post.json
		\cp -a -r /tmp/btwaf/rule/cn.json $btwaf_path/rule/cn.json
		\cp -a -r /tmp/btwaf/rule/cookie.json $btwaf_path/rule/cookie.json
		\cp -a -r /tmp/btwaf/rule/head_white.json $btwaf_path/rule/head_white.json
		\cp -a -r /tmp/btwaf/rule/ip_black.json $btwaf_path/rule/ip_black.json
		\cp -a -r /tmp/btwaf/rule/ip_white.json $btwaf_path/rule/ip_white.json
		\cp -a -r /tmp/btwaf/rule/scan_black.json $btwaf_path/rule/scan_black.json
		\cp -a -r /tmp/btwaf/rule/url_black.json $btwaf_path/rule/url_black.json
		\cp -a -r /tmp/btwaf/rule/url_white.json $btwaf_path/rule/url_white.json
		\cp -a -r /tmp/btwaf/rule/user_agent.json $btwaf_path/rule/user_agent.json
		\cp -a -r /tmp/btwaf/rule/cc_uri_white.json $btwaf_path/rule/cc_uri_white.json 
		\cp -a -r /tmp/btwaf/1.json $btwaf_path/1.json
		\cp -a -r /tmp/btwaf/2.json $btwaf_path/2.json
		\cp -a -r /tmp/btwaf/3.json $btwaf_path/3.json
		\cp -a -r /tmp/btwaf/4.json $btwaf_path/4.json
		\cp -a -r /tmp/btwaf/5.json $btwaf_path/5.json
		\cp -a -r /tmp/btwaf/6.json $btwaf_path/6.json
		\cp -a -r /tmp/btwaf/zhi.json $btwaf_path/zhi.json
	fi
	
	if [ ! -f $btwaf_path/webshell.json ];then
		\cp -a -r /tmp/btwaf/webshell.json $btwaf_path/webshell.json
	fi
	
	if [ ! -f $btwaf_path/webshell_url.json ];then
		\cp -a -r /tmp/btwaf/webshell_url.json $btwaf_path/webshell_url.json
	fi
	
	
	if [ ! -f $btwaf_path/rule/cc_uri_white.json ];then
		\cp -a -r /tmp/btwaf/rule/cc_uri_white.json $btwaf_path/rule/cc_uri_white.json
	fi
	
	if [ ! -f /dev/shm/stop_ip.json ];then
		\cp -a -r /tmp/btwaf/stop_ip.json /dev/shm/stop_ip.json
	fi
	chmod 777 /dev/shm/stop_ip.json
	chown www:www /dev/shm/stop_ip.json
	
	
	if [ ! -f $btwaf_path/site.json ];then
		\cp -a -r /tmp/btwaf/site.json $btwaf_path/site.json
	fi
	
	if [ ! -f $btwaf_path/config.json ];then
		\cp -a -r /tmp/btwaf/config.json $btwaf_path/config.json
	fi
	
	if [ ! -f $btwaf_path/total.json ];then
		\cp -a -r /tmp/btwaf/total.json $btwaf_path/total.json
	fi
	
	if [ ! -f $btwaf_path/drop_ip.log ];then
		\cp -a -r /tmp/btwaf/drop_ip.log $btwaf_path/drop_ip.log
	fi
	if [ ! -b  /www/server/btwaf/captcha/num2.json ];then
		\cp -a -r /tmp/btwaf/9.1.lua $btwaf_path/init.lua
	else 
		\cp -a -r /tmp/btwaf/xiu29.lua $btwaf_path/init.lua
	fi
	\cp -a -r /tmp/btwaf/body_lua2.lua $btwaf_path/body.lua
	\cp -a -r /tmp/btwaf/waf.lua $btwaf_path/waf.lua
	chmod +x $btwaf_path/waf.lua
	chmod +x $btwaf_path/init.lua
	
	mkdir -p /www/wwwlogs/btwaf
	chmod 777 /www/wwwlogs/btwaf
	chmod -R 755 /www/server/btwaf
	chmod -R 666 /www/server/btwaf/rule
	chmod -R 666 /www/server/btwaf/total.json
	chmod -R 666 /www/server/btwaf/drop_ip.log
	echo '' > /www/server/nginx/conf/luawaf.conf
	\cp -a -r /tmp/btwaf/rule/cn.json $btwaf_path/rule/cn.json

	rm -rf /tmp/btwaf
	chown www:www -R /www/server/btwaf/
	/etc/init.d/nginx reload
	bash /www/server/panel/init.sh start
	echo > /www/server/panel/data/restart.pl
	echo '安装完成' > $install_tmp
}


Install_cjson()
{
	if [ -f /usr/bin/yum ];then
		isInstall=`rpm -qa |grep lua-devel`
		if [ "$isInstall" == "" ];then
			yum install lua lua-devel -y
			yum install lua-socket -y
		fi
	else
		isInstall=`dpkg -l|grep liblua5.1-0-dev`
		if [ "$isInstall" == "" ];then
			apt-get install lua5.1 lua5.1-dev -y
		fi
	fi
	if [ ! -f /usr/local/lib/lua/5.1/cjson.so ];then
		wget -O lua-cjson-2.1.0.tar.gz $download_Url/install/src/lua-cjson-2.1.0.tar.gz -T 20
		tar xvf lua-cjson-2.1.0.tar.gz
		rm -f lua-cjson-2.1.0.tar.gz
		cd lua-cjson-2.1.0
		make clean
		
		make
		
		make install
		cd ..
		rm -rf lua-cjson-2.1.0
		ln -sf /usr/local/lib/lua/5.1/cjson.so /usr/lib64/lua/5.1/cjson.so
		ln -sf /usr/local/lib/lua/5.1/cjson.so /usr/lib/lua/5.1/cjson.so
	else
		if [ -d "/usr/lib64/lua/5.1" ];then
			ln -sf /usr/local/lib/lua/5.1/cjson.so /usr/lib64/lua/5.1/cjson.so
		fi
		
		if [ -d "/usr/lib/lua/5.1" ];then
			ln -sf /usr/local/lib/lua/5.1/cjson.so /usr/lib/lua/5.1/cjson.so
		fi
	fi
}


Install_socket()
{	
    #rm -rf /usr/local/lib/lua/5.1/socket/core.so 
	if [ ! -f /usr/local/lib/lua/5.1/socket/core.so ];then
		wget -O luasocket-master.zip $download_Url/install/src/luasocket-master.zip -T 20
		unzip luasocket-master.zip
		rm -f luasocket-master.zip
		cd luasocket-master
		export C_INCLUDE_PATH=/usr/local/include/luajit-2.0:$C_INCLUDE_PATH
		make
		make install
		cd ..
		rm -rf luasocket-master
	fi
	rm -rf /usr/share/lua/5.1/socket

	if [ ! -d /usr/share/lua/5.1/socket ]; then
		if [ -d /usr/lib64/lua/5.1 ];then
			mkdir /usr/lib64/lua/5.1/
			rm -rf /usr/lib64/lua/5.1/socket /usr/lib64/lua/5.1/mime
			ln -sf /usr/local/lib/lua/5.1/socket /usr/lib64/lua/5.1/socket
			ln -sf /usr/local/lib/lua/5.1/mime /usr/lib64/lua/5.1/mime
		else
			rm -rf /usr/lib/lua/5.1/socket /usr/lib/lua/5.1/mime
			mkdir -p /usr/lib/lua/5.1/
			ln -sf /usr/local/lib/lua/5.1/socket /usr/lib/lua/5.1/socket
			ln -sf /usr/local/lib/lua/5.1/mime /usr/lib/lua/5.1/mime
		fi
		rm -rf /usr/share/lua/5.1/mime.lua /usr/share/lua/5.1/socket.lua /usr/share/lua/5.1/socket
		mkdir -p /usr/share/lua/5.1/ 
		mkdir -p /www/server/btwaf/
		ln -sf /usr/local/share/lua/5.1/mime.lua /usr/share/lua/5.1/mime.lua
		ln -sf /usr/local/share/lua/5.1/socket.lua /usr/share/lua/5.1/socket.lua
		ln -sf /usr/local/share/lua/5.1/socket /usr/share/lua/5.1/socket
		
		ln -sf /usr/local/share/lua/5.1/mime.lua /www/server/btwaf/mime.lua
		ln -sf /usr/local/share/lua/5.1/socket.lua /www/server/btwaf/socket.lua
		ln -sf /usr/local/share/lua/5.1/socket /www/server/btwaf/socket	
	fi
}

Uninstall_btwaf()
{
	rm -rf /www/server/panel/static/btwaf
	rm -f /www/server/panel/vhost/nginx/btwaf.conf
	rm -rf /www/server/panel/plugin/btwaf/
	/etc/init.d/nginx reload
}

Check_install(){
if [ ! -d /www/server/btwaf/socket ]; then
	Install_btwaf
fi

}


if [ "${1}" == 'install' ];then
	Install_btwaf
elif  [ "${1}" == 'update' ];then
	Upload_btwaf
elif [ "${1}" == 'uninstall' ];then
	Uninstall_btwaf
fi