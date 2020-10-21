#!/bin/bash

if [[ -n "$RUN_MODE" ]] && [[ "$RUN_MODE" == "Docker" ]]; then
    # 项目名称:如assembly-demo
    SERVICE_NAME="$SERVICE_NAME_DOCKER"
    # 项目全称:如assembly-demo-0.0.1-SNAPSHOT
    SERVICE_FULL_NAME="$SERVICE_FULL_NAME_DOCKER"
    ## Adjust log dir if necessary
else
    # 项目名称:如assembly-demo
    SERVICE_NAME="${project.artifactId}"
    # 项目全称:如assembly-demo-0.0.1-SNAPSHOT
    SERVICE_FULL_NAME="${project.artifactId}-${project.version}"
    ## Adjust log dir if necessary
fi



# 进入bin目录
cd `dirname $0`
# bin目录绝对路径
BIN_DIR=`pwd`
# 返回到上一级项目根目录路径
cd ..
# 打印项目根目录绝对路径
# `pwd` 执行系统命令并获得结果
DEPLOY_DIR=`pwd`

# 外部配置文件绝对目录,如果是目录需要/结尾，也可以直接指定文件
# 如果指定的是目录,spring则会读取目录中的所有配置文件
CONF_DIR=$DEPLOY_DIR/config

# 项目日志输出绝对路径
LOG_DIR=$DEPLOY_DIR/logs

# 项目lib所在绝对路径
LIB_DIR=$DEPLOY_DIR/lib

## Adjust server port if necessary
if [ "$(uname)" == "Darwin" ]; then
    #mac 用于开发sh脚本
    SERVER_PORT=${SERVER_PORT:=8080}
    echo "for mac reason,set SERVER_PORT=$SERVER_PORT"
else
    #linux 用于投产测试
    SERVER_PORT=`sed -nr '/port: [0-9]+/ s/.*port: +([0-9]+).*/\1/p' $CONF_DIR/application.yml`
    echo "the port in application.yml =$SERVER_PORT"

fi

PIDS=`ps -f | grep java | grep "$CONF_DIR" |awk '{print $2}'`
if [ "$1" = "status" ]; then
    if [ -n "$PIDS" ]; then
        echo "The $SERVICE_NAME is running...!"
        echo "PID: $PIDS"
        exit 0
    else
        echo "The $SERVICE_NAME is stopped"
        exit 0
    fi
fi

if [ -n "$PIDS" ]; then
    echo -e "\033[31m ERROR: The $SERVICE_NAME already started! \033[31m"
    echo "PID: $PIDS"
    exit 1
fi

if [ -n "$SERVER_PORT" ]; then
    SERVER_PORT_COUNT=`netstat -tln | grep $SERVER_PORT | wc -l`
    if [ $SERVER_PORT_COUNT -gt 0 ]; then
        echo -e "\033[31m ERROR: The $SERVICE_NAME port $SERVER_PORT already used! \033[31m"
        exit 1
    fi
fi

# 如果logs文件夹不存在,则创建文件夹
if [ ! -d $LOG_DIR ]; then
    mkdir -p $LOG_DIR
fi


# 加载外部log4j2文件的配置
LOG_IMPL_FILE=log4j2.xml
LOGGING_CONFIG=""
if [ -f "$CONF_DIR/$LOG_IMPL_FILE" ];then
     LOGGING_CONFIG="-Dlogging.config=$CONF_DIR/$LOG_IMPL_FILE"
fi
CONFIG_FILES=" -Dlogging.path=$LOG_DIR $LOGGING_CONFIG -Dspring.config.location=$CONF_DIR/ "

## Adjust memory settings if necessary
#export JAVA_OPTS="-Xms6144m -Xmx6144m -Xss256k -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=384m -XX:NewSize=4096m -XX:MaxNewSize=4096m -XX:SurvivorRatio=8"

## Only uncomment the following when you are using server jvm
#export JAVA_OPTS="$JAVA_OPTS -server -XX:-ReduceInitialCardMarks"

########### The following is the same for configservice, adminservice, portal ###########
export JAVA_OPTS="$JAVA_OPTS -XX:ParallelGCThreads=4 -XX:MaxTenuringThreshold=9 -XX:+DisableExplicitGC -XX:+ScavengeBeforeFullGC -XX:SoftRefLRUPolicyMSPerMB=0 -XX:+ExplicitGCInvokesConcurrent -XX:+HeapDumpOnOutOfMemoryError -XX:-OmitStackTraceInFastThrow -Duser.timezone=Asia/Shanghai -Dclient.encoding.override=UTF-8 -Dfile.encoding=UTF-8 -Djava.security.egd=file:/dev/./urandom"

export JAVA_OPTS="$JAVA_OPTS -Dserver.port=$SERVER_PORT  -XX:HeapDumpPath=$LOG_DIR/HeapDumpOnOutOfMemoryError/"


# 可以通过assembly/config/assembly-demo.conf的JAVA_OPTS设置
JAVA_MEM_OPTS=""
BITS=`java -version 2>&1 | grep -i 64-bit`

if [ -n "$BITS" ]; then
    # 64位操作系统的jdk
    JAVA_MEM_OPTS=" -server -Xmx512m -Xms512m -Xmn256m -XX:PermSize=128m -Xss256k -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:+UseCMSCompactAtFullCollection -XX:LargePageSizeInBytes=128m -XX:+UseFastAccessorMethods -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=70 "
else
    # 32位操作系统的jdk
    JAVA_MEM_OPTS=" -server -Xms512m -Xmx512m -XX:PermSize=128m -XX:SurvivorRatio=2 -XX:+UseParallelGC "
fi

JAVA_OPTS="$JAVA_OPTS $JAVA_MEM_OPTS"

#真实存在的jar包，如：assembly-demo-0.0.1-SNAPSHOT.jar
PATH_TO_JAR=$SERVICE_FULL_NAME".jar"
# for test server is successful startup
SERVER_URL="http://localhost:$SERVER_PORT"

function checkPidAlive {
    for i in `ls -t $SERVICE_NAME*.pid 2>/dev/null`
    do
        read pid < $i

        result=$(ps -p "$pid")
        if [ "$?" -eq 0 ]; then
            return 0
        else
            printf "\npid - $pid just quit unexpectedly, please check logs under $LOG_DIR and /tmp for more information!\n"
            exit 1;
        fi
    done

    printf "\nNo pid file found, startup may failed. Please check logs under $LOG_DIR and /tmp for more information!\n"
    exit 1;
}

if [ "$(uname)" == "Darwin" ]; then
    windows="0"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    windows="0"
elif [ "$(expr substr $(uname -s) 1 5)" == "MINGW" ]; then
    windows="1"
else
    windows="0"
fi

# for Windows
if [ "$windows" == "1" ] && [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]]; then
    tmp_java_home=`cygpath -sw "$JAVA_HOME"`
    export JAVA_HOME=`cygpath -u $tmp_java_home`
    echo "Windows new JAVA_HOME is: $JAVA_HOME"
fi

# Find Java
if [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]]; then
    javaexe="$JAVA_HOME/bin/java"
elif type -p java > /dev/null 2>&1; then
    javaexe=$(type -p java)
elif [[ -x "/usr/bin/java" ]];  then
    javaexe="/usr/bin/java"
else
    echo "Unable to find Java"
    exit 1
fi

if [[ "$javaexe" ]]; then
    version=$("$javaexe" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    version=$(echo "$version" | awk -F. '{printf("%03d%03d",$1,$2);}')
    # now version is of format 009003 (9.3.x)
    if [ $version -ge 011000 ]; then
        JAVA_OPTS="$JAVA_OPTS -Xlog:gc*:$LOG_DIR/gc.log:time,level,tags -Xlog:safepoint -Xlog:gc+heap=trace"
    elif [ $version -ge 010000 ]; then
        JAVA_OPTS="$JAVA_OPTS -Xlog:gc*:$LOG_DIR/gc.log:time,level,tags -Xlog:safepoint -Xlog:gc+heap=trace"
    elif [ $version -ge 009000 ]; then
        JAVA_OPTS="$JAVA_OPTS -Xlog:gc*:$LOG_DIR/gc.log:time,level,tags -Xlog:safepoint -Xlog:gc+heap=trace"
    else
        JAVA_OPTS="$JAVA_OPTS -XX:+UseParNewGC"
        JAVA_OPTS="$JAVA_OPTS -Xloggc:$LOG_DIR/gc.log -XX:+PrintGCDetails"
        JAVA_OPTS="$JAVA_OPTS -XX:+UseConcMarkSweepGC -XX:+UseCMSCompactAtFullCollection -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=60 -XX:+CMSClassUnloadingEnabled -XX:+CMSParallelRemarkEnabled -XX:CMSFullGCsBeforeCompaction=9 -XX:+CMSClassUnloadingEnabled  -XX:+PrintGCDateStamps -XX:+PrintGCApplicationConcurrentTime -XX:+PrintHeapAtGC -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=5M"
    fi
fi

#echo "===============================JAVA_OPTS===================================="
#echo "$JAVA_OPTS"
#echo "===============================JAVA_OPTS===================================="

cd $DEPLOY_DIR

# For Docker environment, start in foreground mode
if [[ -n "$RUN_MODE" ]] && [[ "$RUN_MODE" == "Docker" ]]; then
    cd /app/service
    $javaexe -Dsun.misc.URLClassPath.disableJarChecking=true $JAVA_OPTS -jar "./lib/"$PATH_TO_JAR
else
    if [[ -f $SERVICE_NAME".jar" ]]; then
        rm -rf $SERVICE_NAME".jar"
    fi

    printf "$(date) ==== Starting ==== \n"

    ln $LIB_DIR/$PATH_TO_JAR $SERVICE_NAME".jar"
    chmod a+x $SERVICE_NAME".jar"
    ./$SERVICE_NAME".jar" start

    rc=$?;

    if [[ $rc != 0 ]];
    then
        echo "$(date) Failed to start $SERVICE_NAME.jar, return code: $rc"
        exit $rc;
    fi

    declare -i counter=0
    declare -i max_counter=48 # 48*5=240s
    declare -i total_time=0

    printf "Waiting for server startup"
    until [[ (( counter -ge max_counter )) || "$(curl -X GET --silent --connect-timeout 1 --max-time 2 --head $SERVER_URL | grep "HTTP")" != "" ]];
    do
        printf "."
        counter+=1
        sleep 5

        checkPidAlive
    done

    total_time=counter*5

    if [[ (( counter -ge max_counter )) ]];
    then
        printf "\n$(date) Server failed to start in $total_time seconds!\n"
        exit 1;
    fi

    printf "\n$(date) Server started in $total_time seconds!\n"

    exit 0;
fi