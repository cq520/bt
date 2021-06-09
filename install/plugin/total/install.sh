#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
install_tmp='/tmp/bt_install.pl'
public_file=/www/server/panel/install/public.sh
#安装脚本概述
#经过不同的用户安装环境测试，整理安装脚本安装逻辑如下：
#Web Server: nginx, apache
#lua版本: 5.1.4 5.1.5 5.3.1
#OS: CentOS7 CentOS8
#
#nginx和apache单独分开安装逻辑:
#
#因为面板的nginx是固定编译了lua5.1.5，所以nginx的安装统一会安装一个独立的lua5.1.5版本到/www/server/total/lu515,
#用来编译安装luarocks和lsqlite3。
#
#apache的编译跟随OS自带的Lua版本，所以apache默认不安装lua515环境。
#
#所有版本共用一个的lua脚本，已经从lua代码层面解决5.1~5.3的语法不同之处。

if [ ! -f $public_file ];then
        wget -O $public_file http://download.bt.cn/install/public.sh -T 5;
fi

. $public_file
download_Url=$NODE_URL
pluginPath=/www/server/panel/plugin/total
total_path=/www/server/total
remote_dir="total2"

# Returns the platform
Get_platform()
{
    case $(uname -s 2>/dev/null) in
        Linux )                    echo "linux" ;;
        FreeBSD )                  echo "freebsd" ;;
        *BSD* )                    echo "bsd" ;;
        Darwin )                   echo "macosx" ;;
        CYGWIN* | MINGW* | MSYS* ) echo "mingw" ;;
        AIX )                      echo "aix" ;;
        SunOS )                    echo "solaris" ;;
        * )                        echo "unknown"
    esac
}
Remove_path()
{
    local prefix=$1
    local new_path
    new_path=$(echo "${PATH}" | sed \
        -e "s#${prefix}/[^/]*/bin[^:]*:##g" \
        -e "s#:${prefix}/[^/]*/bin[^:]*##g" \
        -e "s#${prefix}/[^/]*/bin[^:]*##g")
    export PATH="${new_path}"
}
Add_path()
{
    local prefix=$1
    local new_path
    new_path=$(echo "${PATH}" | sed \
        -e "s#${prefix}/[^/]*/bin[^:]*:##g" \
        -e "s#:${prefix}/[^/]*/bin[^:]*##g" \
        -e "s#${prefix}/[^/]*/bin[^:]*##g")
    export PATH="${prefix}:${new_path}"
}

Get_lua_version(){
    echo `lua -e 'print(_VERSION:sub(5))'`
}

Install_lua515(){
    local install_path="/www/server/total/lua515"
    
    local version
    version=$(Get_lua_version)

    echo "Current lua version: "$version
    if  [ -d "${install_path}/bin" ]
    then
        Add_path "${install_path}/bin"
        echo "Lua 5.1.5 has installed."
		return 1
    fi
    
    local lua_version="lua-5.1.5"
    local package_name="${lua_version}.tar.gz"
    local url="http://download.bt.cn/install/plugin/${remote_dir}/"$package_name
    mkdir -p $install_path
    local tmp_dir=/tmp/$lua_version
    mkdir -p $tmp_dir && cd $tmp_dir
    wget $url
    tar xvzf $package_name
    cd $lua_version
    platform=$(Get_platform)
    if [ "${platform}" = "unknown" ] 
    then
        platform="linux"
    fi
    make "${platform}" install INSTALL_TOP=$install_path
    Add_path "${install_path}/bin"
    cd /tmp && rm -rf "/tmp/${lua_version}*"

    version=$(Get_lua_version)
    if [ ${version} == "5.1" ]
    then
        echo "Lua 5.1.5 has installed."
        return 1
    fi
    return 0
}
Install_sqlite3_for_nginx()
{

    if [ true ];then
        rm -rf /tmp/luarocks-3.5.0.*
        wget -c -O /tmp/luarocks-3.5.0.tar.gz http://download.bt.cn/btwaf_rule/test/btwaf/luarocks-3.5.0.tar.gz  -T 10
        cd /tmp && tar xf /tmp/luarocks-3.5.0.tar.gz
	    cd /tmp/luarocks-3.5.0
	    ./configure --with-lua-include=/www/server/total/lua515/include --with-lua-bin=/www/server/total/lua515/bin
	    make -I/www/server/total/lua515/bin
	    make install 
	    cd .. && rm -rf /tmp/luarocks-3.5.0.*
    fi

    if [ true ];then
        yum install -y sqlite-devel
        apt install -y libsqlite3-dev
        rm -rf /tmp/lsqlite3_fsl09y*
        wget -c -O /tmp/lsqlite3_fsl09y.zip http://download.bt.cn/btwaf_rule/test/btwaf/lsqlite3_fsl09y.zip  -T 10
        cd /tmp && unzip /tmp/lsqlite3_fsl09y.zip && cd lsqlite3_fsl09y && make
        if [ ! -f '/tmp/lsqlite3_fsl09y/lsqlite3.so' ];then
            echo $tip9
            wget -c -o /www/server/total/lsqlite3.so http://download.bt.cn/btwaf_rule/test/btwaf/lsqlite3.so -T 10
        else
            echo $tip10
            \cp -a -r /tmp/lsqlite3_fsl09y/lsqlite3.so /www/server/total/lsqlite3.so
        fi
        rm -rf /tmp/lsqlite3_fsl09y
        rm -rf /tmp/lsqlite3_fsl09y.zip
    fi
    if [ -f /usr/local/lib/lua/5.1/cjson.so ];then
        is_jit_cjson=$(luajit -e "require 'cjson'" 2>&1|grep 'undefined symbol: luaL_setfuncs')
        if [ "$is_jit_cjson" != "" ];then
            cd /tmp
            luarocks install lua-cjson
        fi
    fi
}

Install_sqlite3_for_apache()
{
    if [ -f '/usr/include/lua.h' ];then 
		include_path='/usr/include/'
	elif [ -f '/usr/local/include/luajit-2.0/lua.h' ];then 
		include_path='/usr/local/include/luajit-2.0/'
	elif [ -f '/usr/include/lua5.1/' ];then 
		include_path='/usr/include/lua5.1/'
	elif [ -f '/usr/local/include/luajit-2.1/' ];then 
		include_path='/usr/local/include/luajit-2.1/'
	else
		include_path=''
	fi
	
    if [ $(Get_lua_version) == "5.3"] && [ -f '/usr/lib64/lua' ];then
        lua_bin='/usr/lib64'
	elif [ -f '/usr/bin/lua' ];then 
		lua_bin='/usr/bin/'
	elif [ -f '/usr/lib/lua' ];then 
		lua_bin='/usr/lib/'
	else
		lua_bin=`which lua | xargs dirname`
	fi
	
	if [ true ];then
		rm -rf /tmp/luarocks-3.5.0.*
		wget -c -O /tmp/luarocks-3.5.0.tar.gz http://download.bt.cn/btwaf_rule/test/btwaf/luarocks-3.5.0.tar.gz  -T 10
		cd /tmp && tar xvf /tmp/luarocks-3.5.0.tar.gz &&  cd /tmp/luarocks-3.5.0 && ./configure --with-lua-bin=$lua_bin --with-lua-include=$include_path
		make -I$include_path && make install && cd .. && rm -rf /tmp/luarocks-3.5.0.*
	fi

    if [ true ];then
        yum install -y sqlite-devel
        apt install -y libsqlite3-dev
        rm -rf /tmp/lsqlite3_fsl09y*
        wget -c -O /tmp/lsqlite3_fsl09y.zip http://download.bt.cn/btwaf_rule/test/btwaf/lsqlite3_fsl09y.zip  -T 10
        cd /tmp && unzip /tmp/lsqlite3_fsl09y.zip && cd lsqlite3_fsl09y && make
        if [ ! -f '/tmp/lsqlite3_fsl09y/lsqlite3.so' ];then
            echo $tip9
            wget -c -o /www/server/total/lsqlite3.so http://download.bt.cn/btwaf_rule/test/btwaf/lsqlite3.so -T 10
        else
            echo $tip10
            \cp -a -r /tmp/lsqlite3_fsl09y/lsqlite3.so /www/server/total/lsqlite3.so
        fi
        rm -rf /tmp/lsqlite3_fsl09y
        rm -rf /tmp/lsqlite3_fsl09y.zip
    fi
    if [ -f /usr/local/lib/lua/5.1/cjson.so ];then
        is_jit_cjson=$(luajit -e "require 'cjson'" 2>&1|grep 'undefined symbol: luaL_setfuncs')
        if [ "$is_jit_cjson" != "" ];then
            cd /tmp
            luarocks install lua-cjson
        fi
    fi
}

Install_cjson()
{
    if [ -f /usr/local/lib/lua/5.1/cjson.so ];then
        is_jit_cjson=$(luajit -e "require 'cjson'" 2>&1|grep 'undefined symbol:luaL_setfuncs')
        if [ "$is_jit_cjson" != "" ];then
                rm -f /usr/local/lib/lua/5.1/cjson.so
        fi
    fi
    if [ -f /usr/bin/yum ];then
        isInstall=`rpm -qa |grep lua-devel`
        if [ "$isInstall" == "" ];then
                yum install lua lua-devel -y
        fi
    else
        isInstall=`dpkg -l|grep liblua5.1-0-dev`
        if [ "$isInstall" == "" ];then
                apt-get install lua5.1 lua5.1-dev lua5.1-cjson lua5.1-socket -y
        fi
    fi

    Centos8Check=$(cat /etc/redhat-release | grep ' 8.' | grep -iE 'centos|Red Hat')
    if [ "${Centos8Check}" ];then
        yum install lua-socket -y
        if [ ! -f /usr/lib/lua/5.3/cjson.so ];then
            wget -O lua-5.3-cjson.tar.gz $download_Url/src/lua-5.3-cjson.tar.gz -T 20
            tar -xvf lua-5.3-cjson.tar.gz
            cd lua-5.3-cjson
            make
            make install
            ln -sf /usr/lib/lua/5.3/cjson.so /usr/lib64/lua/5.3/cjson.so
            cd ..
            rm -f lua-5.3-cjson.tar.gz
            rm -rf lua-5.3-cjson
            return
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
    cd /tmp
    luarocks install lua-cjson
}

Install_socket()
{
    if [ ! -f /usr/local/lib/lua/5.1/socket/core.so ];then
        wget -O luasocket-master.zip $download_Url/install/src/luasocket-master.zip -T 20
        unzip luasocket-master.zip
        rm -f luasocket-master.zip
        cd luasocket-master
        make
        make install
        cd ..
        rm -rf luasocket-master
    fi

    if [ ! -d /usr/share/lua/5.1/socket ]; then
        if [ -d /usr/lib64/lua/5.1 ];then
                rm -rf /usr/lib64/lua/5.1/socket /usr/lib64/lua/5.1/mime
                ln -sf /usr/local/lib/lua/5.1/socket /usr/lib64/lua/5.1/socket
                ln -sf /usr/local/lib/lua/5.1/mime /usr/lib64/lua/5.1/mime
        else
                rm -rf /usr/lib/lua/5.1/socket /usr/lib/lua/5.1/mime
                ln -sf /usr/local/lib/lua/5.1/socket /usr/lib/lua/5.1/socket
                ln -sf /usr/local/lib/lua/5.1/mime /usr/lib/lua/5.1/mime
        fi
        rm -rf /usr/share/lua/5.1/mime.lua /usr/share/lua/5.1/socket.lua /usr/share/lua/5.1/socket
        ln -sf /usr/local/share/lua/5.1/mime.lua /usr/share/lua/5.1/mime.lua
        ln -sf /usr/local/share/lua/5.1/socket.lua /usr/share/lua/5.1/socket.lua
        ln -sf /usr/local/share/lua/5.1/socket /usr/share/lua/5.1/socket
    fi
    cd /tmp
    luarocks install luasocket
}

Install_mod_lua_for_apache()
{
    if [ ! -f /www/server/apache/bin/httpd ];then
            return 0;
    fi

    if [ -f /www/server/apache/modules/mod_lua.so ];then
            return 0;
    fi
    cd /www/server/apache
    if [ ! -d /www/server/apache/src ];then
        wget -O httpd-2.4.33.tar.gz $download_Url/src/httpd-2.4.33.tar.gz -T 20
        tar xvf httpd-2.4.33.tar.gz
        rm -f httpd-2.4.33.tar.gz
        mv httpd-2.4.33 src
        cd /www/server/apache/src/srclib
        wget -O apr-1.6.3.tar.gz $download_Url/src/apr-1.6.3.tar.gz
        wget -O apr-util-1.6.1.tar.gz $download_Url/src/apr-util-1.6.1.tar.gz
        tar zxf apr-1.6.3.tar.gz
        tar zxf apr-util-1.6.1.tar.gz
        mv apr-1.6.3 apr
        mv apr-util-1.6.1 apr-util
    fi
    cd /www/server/apache/src
    ./configure --prefix=/www/server/apache --enable-lua
    cd modules/lua
    make
    make install

    if [ ! -f /www/server/apache/modules/mod_lua.so ];then
        echo $tip8;
        exit 0;
    fi
}

Install_nginx_environment()
{
    echo "Installing nginx environment..."
    Install_lua515
    Install_sqlite3_for_nginx
    Install_cjson
}

Install_apache_environment()
{
    echo "Installing apache environment..."
    Install_mod_lua_for_apache
    Install_sqlite3_for_apache
    Install_cjson
    Install_socket
}

Install_environment()
{
    if [ ! -f /usr/include/linux/limits.h ];then
        yum install kernel-headers -y
    fi
    if [ -f /www/server/apache/bin/httpd ];then
        Install_apache_environment    
    elif [ -f /www/server/nginx/sbin/nginx ];then
        Install_nginx_environment
    else
        echo "Please install nginx or apache first."
    fi
}

tip1="检测到当前面板安装了云控，请暂时使用旧版本监控报表。"
tip2="开始安装旧版本监控报表v3.7..."
tip3="正在安装插件脚本文件..."
tip4="正在初始化数据..."
tip5="开始执行插件补丁..."
tip6="数据初始化完成。"
tip7="安装完成。"
tip8='mod_lua安装失败!'
tip9='解压不成功'
tip10='解压成功'

Install_total()
{
    # if [ -f /www/server/coll/baota_coll ]; then
    #     echo $tip1
    #     echo $tip2

    #     sed -i '12a import os, sys #templine102\r\nos.chdir("/www/server/panel") #templine100\r\nsys.path.insert(0, "/www/server/panel")#templine101\r\nsys.path.insert(0,"/www/server/panel/class/")#templine102\r\n' /www/server/panel/class/panelAuth.py
    #     mv /www/server/total/config.json /www/server/total/config.json.bak 
    #     mkdir -p /tmp/test && cd /tmp/test
    #     wget -O /tmp/test/install_3_7.sh $download_Url/install/plugin/total/install_3_7.sh -T 5
    #     sh install_3_7.sh install
    #     rm /tmp/test/install_3_7.sh
    #     sed -i '/#templine10[0-9]/d' /www/server/panel/class/panelAuth.py
    #     return
    # fi

    mkdir -p $pluginPath
    mkdir -p $total_path
    if ! hash gcc 2>/dev/null;then
        yum install -y gcc
    fi
    Install_environment
    echo $tip3 > $install_tmp
    wget -O $pluginPath/total_main.py $download_Url/install/plugin/$remote_dir/total_main.py -T 5
    wget -O $pluginPath/tsqlite.py $download_Url/install/plugin/$remote_dir/tsqlite.py -T 5
    wget -O $pluginPath/index.html $download_Url/install/plugin/$remote_dir/index.html -T 5
    wget -O $pluginPath/info.json $download_Url/install/plugin/$remote_dir/info.json -T 5
    wget -O $pluginPath/icon.png $download_Url/install/plugin/$remote_dir/icon.png -T 5
    wget -O $pluginPath/total_migrate.py $download_Url/install/plugin/$remote_dir/total_migrate.py -T 5
    wget -O $pluginPath/total_patch.py $download_Url/install/plugin/$remote_dir/total_patch.py -T 5
    wget -O $pluginPath/lua_maker.py $download_Url/install/plugin/$remote_dir/lua_maker.py -T 5

    wget -O /www/server/panel/class/monitor.py $download_Url/install/plugin/$remote_dir/panelMonitor.py -T 5

    if [ ! -f $total_path/config.json ];then
        wget -O $total_path/config.json $download_Url/install/plugin/$remote_dir/config.json -T 5
    fi

    touch /www/server/total/debug.log
    chown www:www /www/server/total/debug.log
    
    echo $tip4
    if hash btpip 2>/dev/null; then
        btpython $pluginPath/total_migrate.py
        echo $tip5
        btpython $pluginPath/total_patch.py
    else
        python $pluginPath/total_migrate.py
        echo $tip5
        python $pluginPath/total_patch.py
    fi
    echo $tip6

    if [ ! -f /www/server/panel/BTPanel/static/js/tools.min.js ];then
        wget -O /www/server/panel/BTPanel/static/js/tools.min.js $download_Url/install/plugin/$remote_dir/tools.min.js -T 5
    fi
    if [ ! -f /www/server/panel/BTPanel/static/js/china.js ];then
        wget -O /www/server/panel/BTPanel/static/js/china.js $download_Url/install/plugin/$remote_dir/china.js -T 5
    fi
    wget -O /www/server/total/total_httpd.conf $download_Url/install/plugin/$remote_dir/total_httpd.conf -T 5
    wget -O /www/server/total/total_nginx.conf $download_Url/install/plugin/$remote_dir/total_nginx.conf -T 5
    if [ ! -f /www/server/total/closing ]; then
        \cp /www/server/total/total_httpd.conf /www/server/panel/vhost/apache/total.conf
        \cp /www/server/total/total_nginx.conf /www/server/panel/vhost/nginx/total.conf
    fi

    \cp -a -r /www/server/panel/plugin/total/icon.png /www/server/panel/BTPanel/static/img/soft_ico/ico-total.png
    wget -O /tmp/total.zip $download_Url/install/plugin/$remote_dir/total.zip -T 5
    mkdir -p /tmp/total
    unzip -o /tmp/total.zip -d /tmp/total > /dev/null
    \cp -a -r /tmp/total/total/* $total_path
    rm -rf /tmp/total/
    rm -rf /tmp/total.zip

    chown -R www:www $total_path
    chmod -R 755 $total_path
    chmod +x $total_path/httpd_log.lua && chown -R root:root $total_path/httpd_log.lua
    chmod +x $total_path/nginx_log.lua && chown -R root:root $total_path/nginx_log.lua
    chmod +x $total_path/memcached.lua  && chown -R root:root $total_path/memcached.lua
    chmod +x $total_path/lsqlite3.so  && chown -R root:root $total_path/lsqlite3.so
    chmod +x $total_path/CRC32.lua  && chown -R root:root $total_path/CRC32.lua

    waf=/www/server/panel/vhost/apache/btwaf.conf
    if [ ! -f $waf ];then
        echo "LoadModule lua_module modules/mod_lua.so" > $waf
    fi

    bt reload
    if [ -f /etc/init.d/httpd ];then
        /etc/init.d/httpd reload
    else
        /etc/init.d/nginx reload
    fi

    echo $tip7
    echo $tip7 > $install_tmp
}

Uninstall_total()
{
    if [ -f /www/server/total/uninstall.lua ];then
        lua /www/server/total/uninstall.lua
    fi
    rm -rf /www/server/total
    rm -f /www/server/panel/vhost/apache/total.conf
    rm -f /www/server/panel/vhost/nginx/total.conf
    rm -rf $pluginPath

    if [ -f /etc/init.d/httpd ];then
        if [ ! -d /www/server/panel/plugin/btwaf_httpd ];then
            rm -f /www/server/panel/vhost/apache/btwaf.conf
        fi
        /etc/init.d/httpd reload
    else
        /etc/init.d/nginx reload
    fi
}

if [ "${1}" == 'install' ];then
    Install_total
elif  [ "${1}" == 'update' ];then
    Install_total
elif [ "${1}" == 'uninstall' ];then
    Uninstall_total
fi