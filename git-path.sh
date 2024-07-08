#!/bin/sh

# 获取git入库文件相当于顶层目录的所在路径
# 求出文件的绝对位置，求出仓库的绝对位置，进行相减即可
function git-path-get-file-relatively-path-in-git-root ()
{
    local gfil=$1
    if [ ! -f "$gfil" ]; then
        echo "$0 file-in-git-root"
        return 1
    fi

    local gitROOT=`git rev-parse --show-toplevel 2>/dev/null`
    if [ -z "$gitROOT"  ]; then
        echo "$0 not in git repo."
        return 1
    fi

    local file_base=`basename $gfil`

    ## 求出 文件的绝对位置
    local file_path=""
    file_path=`dirname $gfil;`
    file_path="`cd $file_path;pwd`/"

    ## 相减
    local oldt=`echo $gitROOT| sed 's:\/:\\\/:g'`

    ## 组合
    echo `echo $file_path| sed "s/$oldt\///g"`$file_base
}

