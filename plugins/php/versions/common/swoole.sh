#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

curPath=`pwd`

rootPath=$(dirname "$curPath")
rootPath=$(dirname "$rootPath")
rootPath=$(dirname "$rootPath")
rootPath=$(dirname "$rootPath")
serverPath=$(dirname "$rootPath")
sourcePath=${serverPath}/source/php

actionType=$1
version=$2

LIBNAME=swoole
LIBV=4.8.10

if [ "$version" -lt "70" ];then
	LIBV=1.10.1
elif [ "$version" == "71" ];then
	LIBV=4.5.2
elif [ "$version" == "70" ];then
	LIBV=4.3.0
else
	echo '72+'
fi

if [ "$version" -eq "82" ];then
	echo "not need"
	exit 1
fi

NON_ZTS_FILENAME=`ls $serverPath/php/${version}/lib/php/extensions | grep no-debug-non-zts`
extFile=$serverPath/php/${version}/lib/php/extensions/${NON_ZTS_FILENAME}/${LIBNAME}.so

sysName=`uname`
if [ "$sysName" == "Darwin" ];then
	BAK='_bak'
else
	BAK=''
fi

Install_lib()
{
	isInstall=`cat $serverPath/php/$version/etc/php.ini|grep "${LIBNAME}.so"`
	if [ "${isInstall}" != "" ];then
		echo "php-$version 已安装${LIBNAME},请选择其它版本!"
		return
	fi
	
	if [ ! -f "$extFile" ];then

		php_lib=$sourcePath/php_lib
		mkdir -p $php_lib

		if [ ! -f  $php_lib/${LIBNAME}-${LIBV}.tgz ];then
			wget -O $php_lib/${LIBNAME}-${LIBV}.tgz http://pecl.php.net/get/${LIBNAME}-${LIBV}.tgz
			cd $php_lib
			tar xvf ${LIBNAME}-${LIBV}.tgz
		fi
		cd $php_lib/${LIBNAME}-${LIBV}
		
		$serverPath/php/$version/bin/phpize
		./configure --with-php-config=$serverPath/php/$version/bin/php-config \
		--enable-openssl \
		--with-openssl-dir=$serverPath/lib/openssl \
		--enable-sockets
		make clean && make && make install && make clean
	fi
	
	while [[ ! -f "$extFile" ]];
    do
        echo -e ".\c"
        sleep 0.5
        if [ ! -f "$extFile" ];then
			echo "ERROR!"
		fi
        let n+=1
        if [ $n -gt 8 ];then
        	echo "WAIT " $n "TIMES FAIL!"
            return;
        fi
    done

    echo "" >> $serverPath/php/$version/etc/php.ini
	echo "[${LIBNAME}]" >> $serverPath/php/$version/etc/php.ini
	echo "extension=${LIBNAME}.so" >> $serverPath/php/$version/etc/php.ini
	
	bash ${rootPath}/plugins/php/versions/lib.sh $version restart
	echo '==========================================================='
	echo 'successful!'
}


Uninstall_lib()
{
	if [ ! -f "$serverPath/php/$version/bin/php-config" ];then
		echo "php-$version 未安装,请选择其它版本!"
		return
	fi
	
	if [ ! -f "$extFile" ];then
		echo "php-$version 未安装${LIBNAME},请选择其它版本!"
		return
	fi
	
	echo $serverPath/php/$version/etc/php.ini
	sed -i $BAK "/${LIBNAME}.so/d" $serverPath/php/$version/etc/php.ini
	sed -i $BAK "/${LIBNAME}/d" $serverPath/php/$version/etc/php.ini
		
	rm -f $extFile
	bash ${rootPath}/plugins/php/versions/lib.sh $version restart
	echo '==============================================='
	echo 'successful!'
}



if [ "$actionType" == 'install' ];then
	Install_lib
elif [ "$actionType" == 'uninstall' ];then
	Uninstall_lib
fi