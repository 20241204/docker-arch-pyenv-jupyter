#!/bin/sh

# 换源
# sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories

# 安装一些必备工具
apk add --no-cache tzdata bash shadow make gcc curl \
                   font-noto-cjk font-wqy-zenhei sed \
                   procps grep wget coreutils git \
                   build-base libffi-dev openssl-dev bzip2-dev \
                   zlib-dev xz-dev readline-dev sqlite-dev tk-dev

# 修改时钟
date +'%Y-%m-%d %H:%M:%S'
ln -sfv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
date +'%Y-%m-%d %H:%M:%S'

# 换成 bash
chsh -s /bin/bash

# 创建 sh 符号链接替换
ln -fsv $(command -v bash) $(command -v sh)
#ln -fsv /bin/bash /bin/sh
#ln -fsv /bin/bash /usr/bin/sh
#ln -fsv /usr/bin/bash /bin/sh
#ln -fsv /usr/bin/bash /usr/bin/sh

# 尝试用 bash 环境运行 install.sh
bash install.sh
