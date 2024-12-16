#!/usr/bin/env bash
set -e
set -u

# 修改镜像源函数
modify_sources(){
    # 备份原始的 sources.list 文件
    cp -fv /etc/apt/sources.list /etc/apt/sources.list.bak

    # ARM64 镜像源
    ARM64_SOURCE="deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-updates main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-backports main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-security main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-security main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-proposed main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-proposed main restricted universe multiverse"

    # AMD64 镜像源
    AMD64_SOURCE="deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-updates main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-backports main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-security main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-security main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-proposed main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-proposed main restricted universe multiverse"

    # 检查系统架构
    ARCH=$(uname -m)

    # 替换 sources.list 文件
    if [ "$ARCH" == "aarch64" ]; then
        echo "$ARM64_SOURCE" > /etc/apt/sources.list
    elif [ "$ARCH" == "x86_64" ]; then
        echo "$AMD64_SOURCE" > /etc/apt/sources.list
    else
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi

}

init(){
    # 执行一些操作，例如更新软件包列表
    apt update

    # 安装 bash
    apt -fy install bash

    # 换成 bash
    chsh -s /bin/bash

    # 创建 sh 符号链接替换
    ln -fsv $(command -v bash) $(command -v sh)
    #ln -fsv /bin/bash /bin/sh
    #ln -fsv /bin/bash /usr/bin/sh
    #ln -fsv /usr/bin/bash /bin/sh
    #ln -fsv /usr/bin/bash /usr/bin/sh

    # 改时区 安装基本命令
    date '+%Y-%m-%d %T'
    TZ=':Asia/Shanghai' date '+%Y-%m-%d %T'
    rm -rfv /etc/localtime
    ln -fsv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    echo "Asia/Shanghai" | tee /etc/timezone

    # 安装更新时间工具
    apt -fy install tzdata
    echo "tzdata tzdata/Zones/Asia select Shanghai" | debconf-set-selections
    dpkg-reconfigure tzdata
    date '+%Y-%m-%d %T'

    # 安装 eatmydata 和 aptitude
    apt -fy install eatmydata
    apt -fy install aptitude
    eatmydata aptitude --without-recommends -o APT::Get::Fix-Missing=true -fy update
    eatmydata aptitude --without-recommends -o APT::Get::Fix-Missing=true -fy upgrade
    
    # 安装一些必备工具
    local packages=(
        ca-certificates
        build-essential
        libssl-dev
        zlib1g-dev
        libbz2-dev
        libreadline-dev
        libsqlite3-dev
        curl
        git
        libncursesw5-dev
        xz-utils
        tk-dev
        libxml2-dev
        libxmlsec1-dev
        libffi-dev
        liblzma-dev
        wget
        locales
    )
    # 合并安装
    # eatmydata aptitude --without-recommends -o APT::Get::Fix-Missing=true -fy install "${packages[@]}"
    # 使用 for 循环逐个安装包
    for package in "${packages[@]}"; do
        echo "正在安装: $package"
        eatmydata aptitude --without-recommends -o APT::Get::Fix-Missing=true -fy install "$package" || {
            echo "安装 $package 时出错，停止安装。"
            exit 1
        }
    done
    # 配置简体中文字符集支持
    perl -pi -e 's/^# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/g' /etc/locale.gen
    perl -pi -e 's/^en_GB.UTF-8 UTF-8/# en_GB.UTF-8 UTF-8/g' /etc/locale.gen
    perl -pi -e 's/^zh_CN GB2312/# zh_CN GB2312/g' /etc/locale.gen
    locale-gen zh_CN.UTF-8

    # 加载简体中文字符集环境变量
    LANGUAGE=zh_CN.UTF-8
    LC_ALL=zh_CN.UTF-8
    LANG=zh_CN.UTF-8
    LC_CTYPE=zh_CN.UTF-8
    
    update-locale LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 LANGUAGE=zh_CN.UTF-8 LC_CTYPE=zh_CN.UTF-8
    # 检查字符集支持
    locale
    locale -a
    cat /etc/default/locale

    # 如果调用了修改镜像源函数，那么一定备份了镜像源
    # 因此判断镜像源原始文件备份，就能恢复原始镜像源
    # 定义镜像源文件路径
    FILE="/etc/apt/sources.list.bak"
    # 判断文件是否存在
    if [ -e "$FILE" ]; then
        # 存在则恢复原始的 sources.list 文件
        mv -fv /etc/apt/sources.list.bak /etc/apt/sources.list
    else
        echo "未调用国内镜像源修改函数 modify_sources()"
    fi

    apt autoremove
    apt clean
    apt autoclean
    rm -frv /var/lib/apt/lists/*
}

# 加载 pyenv 环境变量函数
pyenv_env() {
    # 加载 pyenv 环境变量
    echo '加载 pyenv 环境变量'
    export PYENV_ROOT="$HOME/.pyenv"
    [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
}

install_config_jupyter() {
    # pypi 加速源
    PYPI_CHANNELS=''
    #export PYPI_CHANNELS='-i https://pypi.tuna.tsinghua.edu.cn/simple' 

    # 安装 jupyter notebook 及其扩展
    local jupyter_packages=(
        # 一些软件包可能依赖于 zlib，如果这些软件包在你的环境中不可或缺，安装 zlib 是必要的
        # zlib
        # JupyterLab 是一个基于 Web 的交互式开发环境，用于 Jupyter Notebooks、代码和数据。
        jupyterlab
        # Jupyter Notebook 是一个基于 Web 的应用程序，允许你创建和共享包含代码、方程式、可视化和文本的文档。
        notebook
        # 将 Jupyter Notebooks 转换为独立的 Web 应用程序。
        voila
        # 交互式小部件库，用于在 Jupyter Notebooks 中创建互动组件。
        ipywidgets
        # 一个基于 PyQt 的 Jupyter 控制台，提供与 Jupyter Notebook 类似的功能，但使用 PyQt 库。
        qtconsole
        # 一组社区贡献的 Jupyter Notebook 扩展，提高 Notebook 的功能和用户体验。
        jupyter_contrib_nbextensions
        # 管理和切换不同的 Conda 环境。
        # nb_conda_kernels
        # 用于在 JupyterLab 中集成 Git 版本控制。
        jupyterlab-git
        # 在 JupyterLab 中运行 Dash 应用程序。
        jupyterlab-dash
        # 安装 C 语言解释器，支持 C 语言扩展
        # xeus-cling
        # 科学计算和数据分析的基础包
        numpy
        scipy
        pandas
        matplotlib
        seaborn
        # 机器学习库
        scikit-learn
        # 深度学习 tensorflow
        tensorflow
        # 网络爬虫和数据提取工具
        beautifulsoup4
        requests
        # 数据库抽象层
        SQLAlchemy
        # 简单的重试库
        retrying
        # 现代HTTP客户端，支持异步请求
        httpx
    )

    # 写入 pyenv 环境和简体中文字符集支持写入到环境变量
    cat << '20241204' | tee -a /etc/default/locale /etc/environment $HOME/.bashrc $HOME/.profile
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
LANGUAGE=zh_CN.UTF-8
LC_ALL=zh_CN.UTF-8
LANG=zh_CN.UTF-8
LC_CTYPE=zh_CN.UTF-8
20241204
    if [ ! -d "$HOME/.pyenv" ] ; then
        # 安装 pyenv 管理 python 环境 https://github.com/pyenv/pyenv 
        # 安装脚本 https://github.com/pyenv/pyenv-installer
        curl https://pyenv.run | bash

        # 更新 bash 环境
        cd $HOME/.pyenv/plugins/python-build/../.. && git pull && cd -
        # 加载环境 pyenv
        pyenv_env

        # 安装最新版 python https://github.com/pyenv/pyenv/wiki#suggested-build-environment
        # 构建问题参考 https://github.com/pyenv/pyenv/wiki/Common-build-problems
        # pyenv install -v -f $(pyenv install --list | grep -Eo '^[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+)$' | tail -1)
        pyenv install -v -f 3.12
        
        # 刷新
        pyenv rehash
        # 检查
        pyenv version
        pyenv versions
        
        # 移除已经存在的虚拟环境
        # pyenv_var=`pyenv virtualenvs | grep '*' | awk '{print $2}'`
        # pyenv deactivate $pyenv_var
        # pyenv virtualenv-delete -f $pyenv_var
        # sed -i '/'"${pyenv_var}"'/d' $HOME/.pyenv/version
        
        # 重新创建虚拟python环境
        pyenv_var=`pyenv versions | sed 's;*;;g;s;/; ;g;s; ;;g' | grep -oE '^[0-9]*\.?[0-9]*\.?[0-9]*?$' | awk '{print $1}'`
        pyenv global $pyenv_var
        pyenv virtualenv $pyenv_var py$pyenv_var
        pyenv global py$pyenv_var $pyenv_var
        pyenv activate py$pyenv_var
        
        # python 虚拟环境检查
        pyenv version
        pyenv versions

    fi

    # 创建 python 软链接
    if [ -e $(command -v python3) ]
    then
        ln -fsv $(command -v python3) /usr/bin/python
        ln -fsv $(command -v pip3) /usr/bin/pip
    else
        echo "python3 没找到"
    fi

    # 获取Python版本
    version=$(python --version 2>&1 | awk '{print $2}')
    IFS='.' read -ra ADDR <<< "$version"

    # 检查版本是否为2
    if [[ ${ADDR[0]} -eq 2 ]]
    then
        echo "版本过低 python2"
    elif [[ ${ADDR[0]} -eq 3 ]]
    then
        # 检查版本是否小于等于3.10
        if [[ ${ADDR[1]} -le 10 ]]
        then
            echo "python 版本 ${ADDR[0]}.${ADDR[1]}"
            python -m pip --no-cache-dir install -v --upgrade pip --root-user-action=ignore ${PYPI_CHANNELS}
            # python -m pip --no-cache-dir install -v "${jupyter_packages[@]}" --root-user-action=ignore ${PYPI_CHANNELS}
            # 使用 for 循环逐个安装包
            for package in "${jupyter_packages[@]}"; do
                echo "正在安装: $package"
                python -m pip --no-cache-dir install -v "$package" --root-user-action=ignore ${PYPI_CHANNELS} || {
                    echo "安装 $package 时出错，停止安装。"
                    exit 1
                }
            done
        else
            echo "python 版本 ${ADDR[0]}.${ADDR[1]}"
            python -m pip --no-cache-dir install -v --upgrade pip --break-system-packages --root-user-action=ignore ${PYPI_CHANNELS}
            # python -m pip --no-cache-dir install -v "${jupyter_packages[@]}" --break-system-packages --root-user-action=ignore ${PYPI_CHANNELS}
            # 使用 for 循环逐个安装包
            for package in "${jupyter_packages[@]}"; do
                echo "正在安装: $package"
                python -m pip --no-cache-dir install -v "$package" --break-system-packages --root-user-action=ignore ${PYPI_CHANNELS} || {
                    echo "安装 $package 时出错，停止安装。"
                    exit 1
                }
            done
        fi
    else
        echo "超出版本预期，脚本需要更新！！"
    fi
    # 加载环境 pyenv
    pyenv_env
    # 生成 jupyter 默认配置文件
    echo y | jupyter-notebook --generate-config --allow-root

    # 查看 jupyter 版本
    jupyter --version
    rm -fv requirements.txt
}

config_jbang_ijava(){
    # 安装 JBang 
    curl -Ls https://sh.jbang.dev | bash -s - app setup 
    # 临时添加 JBang 可执行文件在 PATH 中 
    export PATH=$HOME/.jbang/bin:$PATH
    # 添加信任源 
    jbang trust add https://github.com/jupyter-java/jbang-catalog/ 
    jbang trust add https://github.com/jupyter-java/ 
    # 安装 Jupyter for Java Kernel 
    jbang install-kernel@jupyter-java
    # 删除 JAVA 路径
    rm -frv $HOME/.jbang/currentjdk $HOME/.jbang/cache/jdks
}

download_config_jdk() {
    # 获取操作系统类型
    OS=$(uname)
    case $OS in
      'Linux')
        OS='linux'
        Distro="`cat /etc/*-release | grep '^ID='`"
        if [[ "$Distro" == *"alpine"* ]]; then
          OS="alpine-linux"
        fi
        ;;
      'Darwin') 
        OS='mac'
        ;;
      *)
        echo "Unsupported ositecture: $OS"
        exit 1
        ;;
    esac

    # 获取处理器架构类型
    ARCH_RAW=$(uname -m)
    case "$ARCH_RAW" in
    'x86_64') ARCH='x64' ;;
    'aarch64' | 'arm64') ARCH='aarch64' ;;
    *)
        echo "Unsupported architecture: $ARCH_RAW"
        exit 1
        ;;
    esac

    # github 项目 adoptium/temurin23-binaries
    URI="adoptium/temurin23-binaries"
    VERSIONS=$(curl -sL "https://github.com/$URI/releases" | grep -oP '(?<=\/releases\/tag\/)[^"]+' | head -n 1)
    echo $VERSIONS

    VERSION=$(echo ${VERSIONS#jdk-} | sed 's;%2B;_;g')
    echo $VERSION

    URI_DOWNLOAD="https://github.com/$URI/releases/download/${VERSIONS}/OpenJDK23U-jdk_${ARCH}_${OS}_hotspot_${VERSION}.tar.gz"
    echo $URI_DOWNLOAD

    wget -t 3 -T 10 --verbose --show-progress=on --progress=bar --no-check-certificate --hsts-file=/tmp/wget-hsts -c "${URI_DOWNLOAD}" -O"/tmp/OpenJDK-jdk_hotspot.tar.gz"
    
    # 解压缩
    tar xvf /tmp/OpenJDK-jdk_hotspot.tar.gz -C /opt/

    # 修改 jbang ijava 软链接
    ln -fsv /opt/$(ls -al /opt | grep jdk | awk '{print $9}' | tail -1) $HOME/.jbang/currentjdk

    # 写入 java 环境变量
    echo "export JAVA_HOME=/opt/$(ls -al /opt | grep jdk | awk '{print $9}' | tail -1)"  | tee -a /etc/default/locale /etc/environment $HOME/.bashrc $HOME/.profile
    cat << '20241204' | tee -a /etc/default/locale /etc/environment $HOME/.bashrc $HOME/.profile
export CLASSPATH=.:$JAVA_HOME/lib
export PATH=$PATH:$JAVA_HOME/bin
20241204
    rm -fv /tmp/OpenJDK-jdk_hotspot.tar.gz
}

export DEBIAN_FRONTEND=noninteractive
# 代理加速，替换成自己的 代理地址(IP) 和 端口(H_P)
#export IP=127.0.0.1 H_P=1234 S_P=12345 ; export http_proxy=http://${IP}:${H_P} https_proxy=http://${IP}:${H_P} all_proxy=socks5://${IP}:${S_P} HTTP_PROXY=http://${IP}:${H_P} HTTPS_PROXY=http://${IP}:${H_P} ALL_PROXY=socks5://${IP}:${S_P}
# 修改 sources 加速源
#modify_sources
init
install_config_jupyter
config_jbang_ijava
download_config_jdk
# 解除代理加速
unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
# 将执行脚本移动到可执行目录并授权
mv -fv run_jupyter /usr/bin/
chmod -v a+x /usr/bin/run_jupyter
