#!/usr/bin/env bash

# 配置 pyenv 安装 python
config_pyenv() {
    # 将执行脚本移动到可执行目录并授权
    mv -fv run_jupyter /usr/bin/
    chmod -v u+x /usr/bin/run_jupyter
    
    # 写入汉化配置环境
    cat << 20241204 | tee -a /etc/environment
LANG=zh_CN.UTF-8
LC_CTYPE="zh_CN.UTF-8"
LC_NUMERIC="zh_CN.UTF-8"
LC_TIME="zh_CN.UTF-8"
LC_COLLATE="zh_CN.UTF-8"
LC_MONETARY="zh_CN.UTF-8"
LC_MESSAGES="zh_CN.UTF-8"
LC_PAPER="zh_CN.UTF-8"
LC_NAME="zh_CN.UTF-8"
LC_ADDRESS="zh_CN.UTF-8"
LC_TELEPHONE="zh_CN.UTF-8"
LC_MEASUREMENT="zh_CN.UTF-8"
LC_IDENTIFICATION="zh_CN.UTF-8"
LC_ALL=
20241204
    
    # 安装 pyenv 管理 python 环境 https://github.com/pyenv/pyenv 
    # 安装脚本 https://github.com/pyenv/pyenv-installer
    curl https://pyenv.run | sh
    
    # 写入 pyenv 环境
    cat << 20241204 | tee -a $HOME/.bashrc
#!/bin/bash
export PYENV_ROOT="\$HOME/.pyenv"
[[ -d \$PYENV_ROOT/bin ]] && export PATH="\$PYENV_ROOT/bin:\$PATH"
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
20241204
    
    export PYENV_ROOT="$HOME/.pyenv"
    [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
    export PYENV_VIRTUALENV_DISABLE_PROMPT=1
    
    # 更新 bash 环境
    cd $HOME/.pyenv/plugins/python-build/../.. && git pull && cd -
    
    # 安装最新版 python https://github.com/pyenv/pyenv/wiki#suggested-build-environment
    # 构建问题参考 https://github.com/pyenv/pyenv/wiki/Common-build-problems
    pyenv install -v -f $(pyenv install --list | grep -Eo '^[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+)$' | tail -1) versions
    
    # 刷新
    pyenv rehash
    # 检查
    pyenv version
    pyenv versions
    
    # 移除已经存在的虚拟环境
    pyenv_var=`pyenv virtualenvs | grep '*' | awk '{print $2}'`
    pyenv deactivate $pyenv_var
    pyenv virtualenv-delete -f $pyenv_var
    sed -i '/'"${pyenv_var}"'/d' $HOME/.pyenv/version
    
    # 重新创建虚拟python环境
    pyenv_var=`pyenv versions | sed 's;*;;g;s;/; ;g;s; ;;g' | grep -oE '^[0-9]*\.?[0-9]*\.?[0-9]*?$' | awk '{print $1}'`
    pyenv global $pyenv_var
    pyenv virtualenv $pyenv_var py$pyenv_var
    pyenv global py$pyenv_var $pyenv_var
    pyenv activate py$pyenv_var
    
    # python 虚拟环境检查
    pyenv version
    pyenv versions
}

# 安装配置 jupyter
install_config_jupyter() {
    # pypi 加速源
    PYPI_CHANNELS=''
    #export PYPI_CHANNELS='-i https://pypi.tuna.tsinghua.edu.cn/simple' 

    # 安装 jupyter notebook 及其扩展
    local jupyter_packages=(
        # 一些软件包可能依赖于 zlib，如果这些软件包在你的环境中不可或缺，安装 zlib 是必要的
        zlib
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
        nb_conda_kernels
        # 用于在 JupyterLab 中集成 Git 版本控制。
        jupyterlab-git
        # 在 JupyterLab 中运行 Dash 应用程序。
        jupyterlab-dash
        # 安装 C 语言解释器，支持 C 语言扩展
        xeus-cling
        # 科学计算和数据分析的基础包
        numpy
        scipy
        pandas
        matplotlib
        seaborn
        # 机器学习库
        scikit-learn
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
            # 根据架构选择安装深度学习框架 tensorflow
            ARCH_RAW=$(uname -m)
            case "$ARCH_RAW" in
            'x86_64')
                jupyter_packages+=(tensorflow)
                ;;
            'aarch64' | 'arm64')
                python -m pip --no-cache-dir install -v tensorflow-aarch64 --root-user-action=ignore ${PYPI_CHANNELS}
                ;;
            *)
                echo "Unsupported architecture: $ARCH_RAW"
                ;;
            esac
            python -m pip --no-cache-dir install -v "${jupyter_packages[@]}" --root-user-action=ignore ${PYPI_CHANNELS}
            # 使用 for 循环逐个安装包
            # for package in "${jupyter_packages[@]}"; do
            #     echo "正在安装: $package"
            #     python -m pip --no-cache-dir install -v "$package" --root-user-action=ignore ${PYPI_CHANNELS} || {
            #         echo "安装 $package 时出错，停止安装。"
            #         exit 1
            #     }
            # done
        else
            echo "python 版本 ${ADDR[0]}.${ADDR[1]}"
            python -m pip --no-cache-dir install -v --upgrade pip --break-system-packages --root-user-action=ignore ${PYPI_CHANNELS}
            # 根据架构选择安装深度学习框架 tensorflow
            ARCH_RAW=$(uname -m)
            case "$ARCH_RAW" in
            'x86_64')
                jupyter_packages+=(tensorflow)
                ;;
            'aarch64' | 'arm64')
                python -m pip --no-cache-dir install -v tensorflow-aarch64 --break-system-packages --root-user-action=ignore ${PYPI_CHANNELS}
                ;;
            *)
                echo "Unsupported architecture: $ARCH_RAW"
                ;;
            esac
            python -m pip --no-cache-dir install -v "${jupyter_packages[@]}" --break-system-packages --root-user-action=ignore ${PYPI_CHANNELS}
            # 使用 for 循环逐个安装包
            # for package in "${jupyter_packages[@]}"; do
            #     echo "正在安装: $package"
            #     python -m pip --no-cache-dir install -v "$package" --break-system-packages --root-user-action=ignore ${PYPI_CHANNELS} || {
            #         echo "安装 $package 时出错，停止安装。"
            #         exit 1
            #     }
            # done
        fi
    else
        echo "超出版本预期，脚本需要更新！！"
    fi

    # 生成 jupyter 默认配置文件
    echo y | jupyter-notebook --generate-config --allow-root
    
    # 查看 jupyter 版本
    jupyter --version
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
    cat << EOF | tee -a $HOME/.bashrc
export CLASSPATH=.:\$JAVA_HOME/lib
export PATH=\$PATH:\$JAVA_HOME/bin
EOF
    rm -fv /tmp/OpenJDK-jdk_hotspot.tar.gz
}

config_pyenv
install_config_jupyter
config_jbang_ijava
download_config_jdk