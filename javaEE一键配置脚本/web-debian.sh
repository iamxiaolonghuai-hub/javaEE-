#!/bin/bash
clear
echo "============================================="
echo " 🚀 Java Web 开发环境 一键自动安装工具 "
echo " 包含：JDK11 + Maven + web 命令 "
echo "============================================="

# 检查 root 权限
if [ $UID -ne 0 ]; then
    echo "❌ 请使用 sudo 运行！"
    exit 1
fi

# ==========================
# 1. 安装 JDK 
# ==========================
echo -e "\n📦 正在安装 JDK ..."
apt update > /dev/null 2>&1
apt install -y jdk-openjdk > /dev/null 2>&1

# ==========================
# 2. 安装 Maven
# ==========================
echo -e "\n📦 正在安装 Maven..."
apt install -y maven > /dev/null 2>&1

# ==========================
# 3. 配置环境变量（永久生效）
# ==========================
echo -e "\n⚙️  配置系统环境变量..."
cat >> /etc/profile << 'EOF'

# Java & Maven Environment
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export M2_HOME=/usr/share/maven
export PATH=$PATH:$JAVA_HOME/bin:$M2_HOME/bin
EOF

# 立即生效
source /etc/profile

# ==========================
# 4. 安装 web 命令工具
# ==========================
echo -e "\n🔧 安装 web 快速命令..."
tee /usr/local/bin/web > /dev/null << 'EOF'
#!/bin/bash
GROUP_ID=""
ARTIFACT_ID=""
RUN_PROJECT=""

while getopts "g:p:r:" opt; do
  case $opt in
    r) RUN_PROJECT=$OPTARG ;;
    \?)
      echo "用法："
      echo "  创建项目：web -g 包名 -p 项目名"
      echo "  快速运行：web -r 已存在项目名"
      exit 1
    ;;
  esac
done

# 快速运行
if [ -n "$RUN_PROJECT" ]; then
  if [ ! -d "$RUN_PROJECT" ]; then
    echo "❌ 项目 $RUN_PROJECT 不存在"
    exit 1
  fi
  echo "==================================="
  echo "🚀 启动项目：$RUN_PROJECT"
  echo "🌐 访问：http://localhost:8080/$RUN_PROJECT"
  echo "==================================="
  cd "$RUN_PROJECT" && mvn jetty:run
  exit 0
fi

# 创建项目
if [ -z "$GROUP_ID" ] || [ -z "$ARTIFACT_ID" ]; then
  echo "❌ 用法：web -g com.test -p myweb"
  echo "✅ 快速运行：web -r myweb"
  exit 1
fi

echo "==================================="
echo "📦 创建 Java Web 项目：$ARTIFACT_ID"
echo "==================================="

mvn archetype:generate \
  -DgroupId="$GROUP_ID" \
  -DartifactId="$ARTIFACT_ID" \
  -DarchetypeArtifactId=maven-archetype-webapp \
  -DinteractiveMode=false

cd "$ARTIFACT_ID" || exit

cat > pom.xml << XML
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>$GROUP_ID</groupId>
    <artifactId>$ARTIFACT_ID</artifactId>
    <packaging>war</packaging>
    <version>1.0-SNAPSHOT</version>
    <build>
        <plugins>
            <plugin>
                <groupId>org.eclipse.jetty</groupId>
                <artifactId>jetty-maven-plugin</artifactId>
                <version>9.4.54.v20240208</version>
                <configuration>
                    <webApp>
                        <contextPath>/$ARTIFACT_ID</contextPath>
                    </webApp>
                    <httpConnector>
                        <port>8080</port>
                    </httpConnector>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
XML

echo "==================================="
echo "✅ 项目创建完成！"
echo "▶  下次启动：web -r $ARTIFACT_ID"
echo "🌐 访问地址：http://localhost:8080/$ARTIFACT_ID"
echo "==================================="
EOF

chmod +x /usr/local/bin/web

# ==========================
# 安装完成
# ==========================
echo -e "\n============================================="
echo " ✅ 全部安装完成！"
echo "============================================="
echo -e "\n📌 验证环境："
java -version
mvn -v
echo -e "\n📌 使用命令："
echo "  创建项目：web -g com.test -p myweb"
echo "  快速运行：web -r myweb"
