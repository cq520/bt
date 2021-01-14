#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
install_tmp='/tmp/bt_install.pl'
public_file=/www/server/panel/install/public.sh
if [ ! -f $public_file ];then
  wget -O $public_file http://download.bt.cn/install/public.sh -T 5
fi
. $public_file
download_Url=$NODE_URL
echo 'download url...'
echo $download_Url
pluginPath=/www/server/panel/plugin/mail_sys
pluginStaticPath=/www/server/panel/plugin/mail_sys/static

cpu_arch=`arch`
if [[ $cpu_arch != "x86_64" ]];then
  echo '不支持非x86的系统安装'
  exit 0
fi

if [ -f "/usr/bin/apt-get" ];then
  systemver='ubuntu'
elif [ -f "/etc/redhat-release" ];then
  systemver=`cat /etc/redhat-release|sed -r 's/.* ([0-9]+)\..*/\1/'`
  postfixver=`postconf mail_version|sed -r 's/.* ([0-9\.]+)$/\1/'`
else
  echo '不支持的系统版本'
  exit 0
fi

Install_centos7()
{
  if [[ $cpu_arch != "x86_64" ]];then
    echo '不支持非x86的centos7系统安装'
    exit 0
  fi

  yum install epel-release -y
  # 卸载系统自带的postfix
  if [[ $cpu_arch = "x86_64" && $postfixver != "3.4.7" ]];then
    yum remove postfix -y
    rm -rf /etc/postfix
  fi
  # 安装postfix和postfix-sqlite
  wget -O /tmp/postfix3-3.4.7-1.gf.el7.x86_64.rpm $download_Url/install/plugin/mail_sys/rpm/postfix3-3.4.7-1.gf.el7.x86_64.rpm
  yum localinstall /tmp/postfix3-3.4.7-1.gf.el7.x86_64.rpm -y
  wget -O /tmp/postfix3-sqlite-3.4.7-1.gf.el7.x86_64.rpm $download_Url/install/plugin/mail_sys/rpm/postfix3-sqlite-3.4.7-1.gf.el7.x86_64.rpm
  yum localinstall /tmp/postfix3-sqlite-3.4.7-1.gf.el7.x86_64.rpm -y
  if [[ ! -f "/usr/sbin/postfix" ]]; then
    yum install postfix -y
    yum install postfix-sqlite -y
  fi
  # 安装dovecot
  wget -O /tmp/dovecot23-2.3.10-1.gf.el7.x86_64.rpm $download_Url/install/plugin/mail_sys/rpm/dovecot23-2.3.10-1.gf.el7.x86_64.rpm
  yum localinstall /tmp/dovecot23-2.3.10-1.gf.el7.x86_64.rpm -y
  if [[ ! -f "/usr/sbin/dovecot" ]]; then
    yum install dovecot -y
  fi
  # 安装opendkim
  wget -O /tmp/opendkim-2.11.0-0.1.el7.x86_64.rpm $download_Url/install/plugin/mail_sys/rpm/opendkim-2.11.0-0.1.el7.x86_64.rpm
  yum localinstall /tmp/opendkim-2.11.0-0.1.el7.x86_64.rpm -y
  if [[ ! -f "/usr/sbin/opendkim" ]]; then
    yum install opendkim -y
  fi
  yum install cyrus-sasl-plain -y
}

Install_centos8()
{
  yum install epel-release -y
  # 卸载系统自带的postfix
  if [[ $cpu_arch = "x86_64" && $postfixver != "3.4.9" ]];then
    yum remove postfix -y
    rm -rf /etc/postfix
  fi
  # 安装postfix和postfix-sqlite
  wget -O /tmp/postfix3-3.4.9-1.gf.el8.x86_64.rpm $download_Url/install/plugin/mail_sys/rpm/postfix3-3.4.9-1.gf.el8.x86_64.rpm
  yum localinstall /tmp/postfix3-3.4.9-1.gf.el8.x86_64.rpm -y
  wget -O /tmp/postfix3-sqlite-3.4.9-1.gf.el8.x86_64.rpm $download_Url/install/plugin/mail_sys/rpm/postfix3-sqlite-3.4.9-1.gf.el8.x86_64.rpm
  yum localinstall /tmp/postfix3-sqlite-3.4.9-1.gf.el8.x86_64.rpm -y
  if [[ ! -f "/usr/sbin/postfix" ]]; then
    yum install postfix -y
    yum install postfix-sqlite -y
  fi
  # 安装dovecot
  wget -O /tmp/dovecot23-2.3.10-1.gf.el8.x86_64.rpm $download_Url/install/plugin/mail_sys/rpm/dovecot23-2.3.10-1.gf.el8.x86_64.rpm
  yum localinstall /tmp/dovecot23-2.3.10-1.gf.el8.x86_64.rpm -y
  if [[ ! -f "/usr/sbin/dovecot" ]]; then
    yum install dovecot -y
  fi
  # 安装opendkim
  wget -O /tmp/opendkim-2.11.0-0.9.el8.x86_64.rpm $download_Url/install/plugin/mail_sys/rpm/opendkim-2.11.0-0.9.el8.x86_64.rpm
  yum localinstall /tmp/opendkim-2.11.0-0.9.el8.x86_64.rpm -y
  if [[ ! -f "/usr/sbin/opendkim" ]]; then
    yum install opendkim -y
  fi
  yum install cyrus-sasl-plain -y
}

Install_ubuntu()
{
  hostname=`hostname`
  # 安装postfix和postfix-sqlite
  sudo debconf-set-selections <<< "postfix postfix/mailname string ${hostname}"
  sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
  sudo apt install postfix -y
  sudo apt install postfix-sqlite -y
  sudo apt install sqlite -y
  # 安装dovecot
  sudo apt install dovecot-core dovecot-pop3d dovecot-imapd dovecot-lmtpd dovecot-sqlite -y
  # 安装opendkim
  sudo apt install -y opendkim opendkim-tools
  wget -O /etc/opendkim.zip $download_Url/install/plugin/mail_sys_en/opendkim.zip -T 10
  rm -rf /etc/opendkim_old
  mv /etc/opendkim /etc/opendkim_old
  unzip -d /etc/ /etc/opendkim.zip
  chown -R opendkim.opendkim /etc/opendkim

  sudo apt install cyrus-sasl-plain -y
}

Install()
{
  if [ ! -d /www/server/panel/plugin/mail_sys ];then
    mkdir -p $pluginPath
    mkdir -p $pluginStaticPath

    if [[ $systemver = "7" ]]; then
      Install_centos7
    elif [[ $systemver = "8" ]]; then
      Install_centos8
    else
      Install_ubuntu
    fi
  fi

  filesize=`ls -l /etc/dovecot/dh.pem | awk '{print $5}'`
  echo $filesize

  if [ ! -f "/etc/dovecot/dh.pem" ] || [ $filesize -lt 300 ]; then
    openssl dhparam 2048 > /etc/dovecot/dh.pem
  fi

  echo '正在安装脚本文件...' > $install_tmp

  grep "English" /www/server/panel/config/config.json
  if [ "$?" -ne 0 ]; then
    wget -O $pluginPath/mail_sys_main.py $download_Url/install/plugin/mail_sys/mail_sys_main.py -T 5
    wget -O $pluginPath/receive_mail.py $download_Url/install/plugin/mail_sys/receive_mail.py -T 5
    wget -O $pluginPath/index.html $download_Url/install/plugin/mail_sys/index.html -T 5
    wget -O $pluginPath/info.json $download_Url/install/plugin/mail_sys/info.json -T 5
    wget -O $pluginPath/icon.png $download_Url/install/plugin/mail_sys/icon.png -T 5
    wget -O $pluginStaticPath/api.zip $download_Url/install/plugin/mail_sys/api.zip -T 5
    wget -O /www/server/panel/BTPanel/static/ckeditor.zip $download_Url/install/plugin/mail_sys/ckeditor.zip -T 5
  else
    wget -O $pluginPath/mail_sys_main.py $download_Url/install/plugin/mail_sys_en/mail_sys_main.py -T 5
    wget -O $pluginPath/receive_mail.py $download_Url/install/plugin/mail_sys_en/receive_mail.py -T 5
    wget -O $pluginPath/index.html $download_Url/install/plugin/mail_sys_en/index.html -T 5
    wget -O $pluginPath/info.json $download_Url/install/plugin/mail_sys_en/info.json -T 5
    wget -O $pluginPath/icon.png $download_Url/install/plugin/mail_sys_en/icon.png -T 5
    wget -O $pluginStaticPath/api.zip $download_Url/install/plugin/mail_sys_en/api.zip -T 5
    wget -O /www/server/panel/BTPanel/static/ckeditor.zip $download_Url/install/plugin/mail_sys_en/ckeditor.zip -T 5
  fi
  if [ ! -d "/www/server/panel/BTPanel/static/ckeditor" ]; then
    unzip /www/server/panel/BTPanel/static/ckeditor.zip -d /www/server/panel/BTPanel/static
  fi

  echo '安装完成' > $install_tmp
}

#更新
Update()
{
  grep "English" /www/server/panel/config/config.json
  if [ "$?" -ne 0 ]; then
    wget -O $pluginPath/mail_sys_main.py $download_Url/install/plugin/mail_sys/mail_sys_main.py -T 5
    wget -O $pluginPath/receive_mail.py $download_Url/install/plugin/mail_sys/receive_mail.py -T 5
    wget -O $pluginPath/index.html $download_Url/install/plugin/mail_sys/index.html -T 5
    wget -O $pluginPath/info.json $download_Url/install/plugin/mail_sys/info.json -T 5
    wget -O $pluginPath/icon.png $download_Url/install/plugin/mail_sys/icon.png -T 5
    wget -O $pluginStaticPath/api.zip $download_Url/install/plugin/mail_sys/api.zip -T 5
    wget -O /www/server/panel/BTPanel/static/ckeditor.zip $download_Url/install/plugin/mail_sys/ckeditor.zip -T 5
  else
    wget -O $pluginPath/mail_sys_main.py $download_Url/install/plugin/mail_sys_en/mail_sys_main.py -T 5
    wget -O $pluginPath/receive_mail.py $download_Url/install/plugin/mail_sys_en/receive_mail.py -T 5
    wget -O $pluginPath/index.html $download_Url/install/plugin/mail_sys_en/index.html -T 5
    wget -O $pluginPath/info.json $download_Url/install/plugin/mail_sys_en/info.json -T 5
    wget -O $pluginPath/icon.png $download_Url/install/plugin/mail_sys_en/icon.png -T 5
    wget -O $pluginStaticPath/api.zip $download_Url/install/plugin/mail_sys_en/api.zip -T 5
    wget -O /www/server/panel/BTPanel/static/ckeditor.zip $download_Url/install/plugin/mail_sys_en/ckeditor.zip -T 5
  fi
  if [ -d "/www/server/panel/BTPanel/static/ckeditor" ]; then
    rm -rf /www/server/panel/BTPanel/static/ckeditor
    unzip /www/server/panel/BTPanel/static/ckeditor.zip -d /www/server/panel/BTPanel/static
  fi
}

#卸载
Uninstall()
{
  if [[ $systemver = "7" ]]; then
    yum remove postfix -y
    yum remove dovecot -y
    yum remove opendkim -y
  elif [ $systemver = "8" ]; then
    yum remove postfix -y
    yum remove dovecot -y
    yum remove opendkim -y
  else
    sudo apt remove postfix postfix-sqlite -y && rm -rf /etc/postfix
    dpkg -P postfix postfix-sqlite
    sudo apt remove dovecot-core dovecot-imapd dovecot-lmtpd dovecot-pop3d dovecot-sqlite -y
    dpkg -P dovecot-core dovecot-imapd dovecot-lmtpd dovecot-pop3d dovecot-sqlite
    sudo apt remove opendkim opendkim-tools -y
    dpkg -P opendkim opendkim-tools
  fi

  rm -rf /etc/postfix
  rm -rf /etc/dovecot
  rm -rf /etc/opendkim

  rm -rf $pluginPath
}

#操作判断
if [ "${1}" == 'install' ]; then
  Install
elif  [ "${1}" == 'update' ]; then
  Update
elif [ "${1}" == 'uninstall' ]; then
  Uninstall
fi
