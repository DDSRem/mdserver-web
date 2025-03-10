#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#https://dev.mysql.com/downloads/mysql/5.5.html#downloads
#https://dev.mysql.com/downloads/file/?id=480541

curPath=`pwd`
rootPath=$(dirname "$curPath")
rootPath=$(dirname "$rootPath")
serverPath=$(dirname "$rootPath")
sysName=`uname`

install_tmp=${rootPath}/tmp/mw_install.pl
mariadbDir=${serverPath}/source/mariadb

MY_VER=10.6.8

Install_app()
{
	mkdir -p ${mariadbDir}
	echo '正在安装脚本文件...' > $install_tmp

	if id mysql &> /dev/null ;then 
	    echo "mysql UID is `id -u www`"
	    echo "mysql Shell is `grep "^www:" /etc/passwd |cut -d':' -f7 `"
	else
	    groupadd mysql
		useradd -g mysql mysql
	fi

	if [ "$sysName" != "Darwin" ];then
		mkdir -p /var/log/mariadb
		touch /var/log/mariadb/mariadb.log
	fi 

	if [ ! -f ${mariadbDir}/mariadb-${MY_VER}.tar.gz ];then
		wget -O ${mariadbDir}/mariadb-${MY_VER}.tar.gz --tries=3 https://downloads.mariadb.org/interstitial/mariadb-${MY_VER}/source/mariadb-${MY_VER}.tar.gz
	fi

	if [ ! -d ${mariadbDir}/mariadb-${MY_VER} ];then
		 cd ${mariadbDir} && tar -zxvf  ${mariadbDir}/mariadb-${MY_VER}.tar.gz
	fi
	

	if [ ! -d $serverPath/mariadb ];then
		cd ${mariadbDir}/mariadb-${MY_VER} && cmake \
		-DCMAKE_INSTALL_PREFIX=$serverPath/mariadb \
		-DMYSQL_DATADIR=$serverPath/mariadb/data/ \
		-DMYSQL_USER=mysql \
		-DMYSQL_UNIX_ADDR=$serverPath/mariadb/mysql.sock \
		-DWITH_MYISAM_STORAGE_ENGINE=1 \
		-DWITH_INNOBASE_STORAGE_ENGINE=1 \
		-DWITH_MEMORY_STORAGE_ENGINE=1 \
		-DENABLED_LOCAL_INFILE=1 \
		-DWITH_PARTITION_STORAGE_ENGINE=1 \
		-DEXTRA_CHARSETS=all \
		-DDEFAULT_CHARSET=utf8mb4 \
		-DDEFAULT_COLLATION=utf8mb4_general_ci \
		-DCMAKE_C_COMPILER=/usr/bin/gcc \
		-DCMAKE_CXX_COMPILER=/usr/bin/g++
		make && make install && make clean

		if [ -d $serverPath/mariadb ];then
			echo '10.6' > $serverPath/mariadb/version.pl
			echo '安装完成' > $install_tmp
		else
			# rm -rf ${mariadbDir}/mariadb-${MY_VER}
			echo '安装失败' > $install_tmp
			echo 'install fail'>&2
			exit 1
		fi
	fi
}

Uninstall_app()
{
	rm -rf $serverPath/mariadb
	echo '卸载完成' > $install_tmp
}

action=$1
if [ "${1}" == 'install' ];then
	Install_app
else
	Uninstall_app
fi
