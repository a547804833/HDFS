#!/bin/bash
############################################
#
#   易度系统Linux版本运维辅助工具
#   2018-10-07.Version 1.0 By LNS
# 
#############################################

#系统常用变量设置
#字体颜色
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Yellow_font_prefix="\033[33m" && Font_color_suffix="\033[0m"
#提示信息
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Yellow_font_prefix}[注意]${Font_color_suffix}"



function Install_jdk(){
  # java_pth=/usr/java/jdk1.7.0_79

  #在usr目录下新建java文件夹
  echo -e  "${Info}在usr目录下新建java文件夹"
  mkdir -p /usr/java

  #下载jdk1.7到/usr/java
  echo -e  "${Info}下载jdk1.7到/usr/java"
  #wget -P /usr/java https://media.githubusercontent.com/media/a547804833/JDK/master/jdk/jdk-7u79-linux-x64.tar.gz

  #解压jdk包到/usr/java
  echo -e  "${Info}解压jdk包到/usr/java"
  cd /usr/java
  tar -zxvf jdk-7u79-linux-x64.tar.gz -C /usr/java

  #追加jdk环境变量到/etc/profile
  echo -e  "${Info}追加jdk环境变量到/etc/profile"
cat <<EOF >>/etc/profile
#set java environment
JAVA_HOME=$java_pth
JRE_HOME=$java_pth/jre
CLASS_PATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar:\$JRE_HOME/lib
PATH=\$PATH:\$JAVA_HOME/bin:\$JRE_HOME/bin
export JAVA_HOME JRE_HOME CLASS_PATH PATH
EOF

source /etc/profile


}

function Local_Mode(){

  node1=127.0.0.1
  java_pth=/usr/java/jdk1.7.0_79

  Install_jdk

  #在usr目录下新建hadoop文件夹
  echo -e  "${Info}在usr目录下新建hadoop文件夹" 
  mkdir -p /usr/hadoop

  #下载hadoop2.8.5到/usr/hadoop
  echo -e  "${Info}下载hadoop2.8.5到/usr/hadoop" 
  # wget -P /usr/hadoop http://mirror.bit.edu.cn/apache/hadoop/common/hadoop-2.8.5/hadoop-2.8.5.tar.gz

  #解压hadoop2.8.5包到/usr/hadoop
  echo -e  "${Info}解压hadoop2.8.5包到/usr/hadoop"
  cd /usr/hadoop
  tar -zxvf hadoop-2.8.5.tar.gz -C /usr/hadoop


#设置hadoop的环境变量并生效
echo -e  "${Info}设置etc/hadoop/hadoop-env.sh环境变量为JDK安装的根目录"
cat <<EOF>>/etc/profile
export HADOOP_HOME=/usr/hadoop/hadoop-2.8.5
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
EOF

source /etc/profile


#设置为Java安装的根目录,hadoop-env.sh
echo -e  "${Info}设置/usr/hadoop/hadoop-2.8.5/etc/hadoop/hadoop-env.sh环境变量为JDK安装的根目录"
cat <<EOF >>/usr/hadoop/hadoop-2.8.5/etc/hadoop/hadoop-env.sh
export JAVA_HOME=$java_pth
EOF


#设置为Java安装的根目录,yarn-env.sh
echo -e  "${Info}设置/usr/hadoop/hadoop-2.8.5/etc/hadoop/yarn-env.sh环境变量为JDK安装的根目录"
cat <<EOF >>/usr/hadoop/hadoop-2.8.5/etc/hadoop/yarn-env.sh
export JAVA_HOME=$java_pth
EOF
exit
source /etc/profile
#master节点设置免密登录，
#原因：HDFS能做到在任何一个机器上敲命令启动HDFS,那么它就能启动所有节点的所有的Java进程(每个节点实际就是一个java 进程)，也就是启动整个集群,其实就是远程登录到其他机器上去启动那些节点.如 start-all.sh命令.它其实只是为了一个方便,不然需要逐个启 动节点.
echo -e  "${Info}设置免密登录"
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys

#配置node1节点./etc/hadoop/core-site.xml
echo -e  "${Info}配置node1节点/usr/hadoop/hadoop-2.8.5/etc/hadoop/core-site.xml"
cat <<EOF > /usr/hadoop/hadoop-2.8.5/etc/hadoop/core-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->
<!-- Put site-specific property overrides in this file. -->
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://${node1}:9000</value>
    </property>
    <property>
        <name>io.file.buffer.size</name>
        <value>131072</value>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>file:/home/hdfs/hadoop/tmp</value>
        <description>Abasefor other temporary directories.</description>
    </property>
    <property>
        <name>hadoop.proxyuser.spark.hosts</name>
        <value>*</value>
    </property>
    <property>
        <name>hadoop.proxyuser.spark.groups</name>
        <value>*</value>
    </property>
</configuration>

EOF

#配置node1节点./etc/hadoop/hdfs-site.xml
echo -e  "${Info}配置node1节点/usr/hadoop/hadoop-2.8.5/etc/hadoop/hdfs-site.xml"
cat <<EOF>/usr/hadoop/hadoop-2.8.5/etc/hadoop/hdfs-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->
<!-- Put site-specific property overrides in this file. -->
<configuration>
    <property>
        <name>dfs.namenode.secondary.http-address</name>
        <value>${node1}:9001</value>
    </property>

    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file:/home/hdfs/hadoop/name</value>
    </property>

    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file:/home/hdfs/hadoop/data</value>
    </property>

    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>

    <property>
        <name>dfs.webhdfs.enabled</name>
        <value>true</value>
    </property>

</configuration>
EOF


#配置node1节点./etc/hadoop/mapred-site.xml
echo -e  "${Info}配置node1节点/usr/hadoop/hadoop-2.8.5/etc/hadoop/mapred-site.xml"
cat <<EOF>/usr/hadoop/hadoop-2.8.5/etc/hadoop/mapred-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->
<!-- Put site-specific property overrides in this file. -->

<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.jobhistory.address</name>
        <value>${node1}:10020</value>
    </property>
    <property>
        <name>mapreduce.jobhistory.webapp.address</name>
        <value>${node1}:19888</value>
    </property>
</configuration>
EOF

#配置node1节点./etc/hadoop/yarn-site.xml
echo -e  "${Info}配置node1节点/usr/hadoop/hadoop-2.8.5/etc/hadoop/yarn-site.xml"
cat <<EOF>/usr/hadoop/hadoop-2.8.5/etc/hadoop/yarn-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->
<!-- Put site-specific property overrides in this file. -->
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
        <value>org.apache.hadoop.mapred.ShuffleHandler</value>
    </property>
    <property>
        <name>yarn.resourcemanager.address</name>
        <value>${node1}:8032</value>
    </property>
    <property>
        <name>yarn.resourcemanager.scheduler.address</name>
        <value>${node1}:8030</value>
    </property>
    <property>
        <name>yarn.resourcemanager.resource-tracker.address</name>
        <value>${node1}:8035</value>
    </property>
    <property>
        <name>yarn.resourcemanager.admin.address</name>
        <value>${node1}:8033</value>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address</name>
        <value>${node1}:8088</value>
    </property>

</configuration>
EOF

#给予根目录权限
cd /usr/hadoop/hadoop-2.8.5
source /etc/profile
./bin/hadoop fs  -chmod 777 /


#格式化NameNode
echo -e  "${Info}格式化NameNode"
cd /usr/hadoop/hadoop-2.8.5
./bin/hdfs namenode -format

#启动HDFS
echo -e  "${Info}启动HDFS"
cd /usr/hadoop/hadoop-2.8.5
./sbin/start-dfs.sh

echo -e  "${Info}启动HDFS成功：访问IP:50070"
echo -e  "${Info}请执行:source /etc/profile"
echo -e  "${Info}请执行:hadoop fs  -chmod 777 /"
}

function Pseudo_Distributed_Mode(){
pass
}

function Fully_Distributed_Mode(){
pass
}


#主方法入口
echo -e "
——————————————————————————————————————————————
HDFSLinux版本运维辅助工具
——By LNS Version 1.0 data 2018.11.07
——————————————————————————————————————————————\n
-----请参照docker官方文档安装:http://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/SingleCluster.html。

${Green_font_prefix}1.${Font_color_suffix}本地（独立）模式
${Green_font_prefix}2.${Font_color_suffix}伪分布式模式
${Green_font_prefix}3.${Font_color_suffix}完全分布式模式

------------------------其他
${Green_font_prefix}0.${Font_color_suffix}退出\n"
echo  "按照上述功能说明,输入相应的编号(1-10):" && read num
case ${num} in
0) exit ;;
1) Local_Mode ;;
2) Pseudo_Distributed_Mode ;;
3) Fully_Distributed_Mode ;;


*) echo -e "${Tip}你输入的是:${num},这个功能选项并不在功能列表中" ;;
esac