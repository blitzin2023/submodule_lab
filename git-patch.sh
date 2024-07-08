#!/bin/sh
## git patch 有关的文件

# 打印补丁中的修改文件清单
function git-show-changed-file-list-from-patch ()
{
    local patchFile=$1
    if [ -z "$patchFile" ]; then
        echo "need : patchFile from 'git diff/show/format-patch'"
        return 1
    fi

    cat $patchFile | grep -F 'diff --git a/' | sed "s#diff --git a/##" | awk '{print$1}'
}


function git-patch-show-changed-file-list ()
{
    git-show-changed-file-list-from-patch "$@"
}

# 删除补丁中的文件
function git-patch-remove-file-from-patch ()
{
    local patchFile=$1
    local removeFile=$2
    if [ -z "$patchFile" -o -z "$removeFile" ]; then
        echo "need : patchFile-from-'git diff/show/format-patch'  file-removed"
        return 1
    fi
    local checkFileInPatch=`cat $patchFile| grep -Fn "diff --git a/$removeFile"`
    if [ -z "$checkFileInPatch" ]; then
        echo "not found, try 'git-patch-show-changed-file-list' to make sure."
        return 1
    fi

    local DATE=$(date "+%Y%m%d%H%M%S")
    local nextfile="/tmp/.tmp.git.patch.file.$$.$DATE"
    local cmd_file="/tmp/.tmp.git.patch.file.cmd.$$.$DATE"

    local allFile=`cat $patchFile | grep -F 'diff --git a/' | sed "s#diff --git a/##" | awk '{print$1}'`
    ## 定位起始行
    local txt=`cat $patchFile| grep -Fn "diff --git a/$removeFile"`
    local begin=`echo $txt|  awk -F: '{print$1}'`
    ## 定位末位行（找不到则一直删除到末尾）
    local end=$begin
    #### 输出包括删除文件以内的内容到文件中，便于处理
    cat $patchFile | tail -n +$(($begin+1)) > $nextfile
    #### 逐行解析，累加需要删除的行数
    cat $nextfile  | while read lineForEnd
    do
        local checkNextMark=`echo $lineForEnd | grep -F "diff --git a/"`
        if [ ! -z $checkNextMark ];then
            break;
        fi
        end=$(($end+1))
    done
    (
    cat<<EOF
sed '${begin},${end}d'  -i $patchFile
EOF
    ) >  $cmd_file
    bash $cmd_file
    rm   $cmd_file
    rm   $nextfile
}

# 提取补丁中的新增文件部分
function git-patch-collect-new-file ()
{
    local patchFile=$1
    if [ -z "$patchFile" ]; then
        echo "need : patchFile-from-'git diff/show/format-patch'"
        return 1
    fi
    ## 找到补丁中所有的文件
    local allFile=`cat $patchFile | grep -F 'diff --git a/' | sed "s#diff --git a/##" | awk '{print$1}'`
    local nextfile="/tmp/.tmp.git.patch.file.$$.$DATE"
    local outfile="$patchFile.only.new"
    local cmd_file="/tmp/.tmp.git.patch.file.cmd.$$.$DATE"
    rm -rf $outfile
    echo $allFile  | while read eachFile
    do
        local txt=`cat $patchFile| grep -F -A 3 "diff --git a/$eachFile"`
        local ret=`echo $txt | grep -F "new file mode "`
        if [  -z $ret ];then
            continue
        fi
        ## 这个是一个新增文件
        local newFile="$eachFile"

        ## 定位起始行
        local txt=`cat $patchFile| grep -Fn "diff --git a/$newFile"`
        local begin=`echo $txt|  awk -F: '{print$1}'`
        ## 定位末位行（找不到则一直删除到末尾）
        local end=$begin
        #### 输出包括新文件以内的内容到文件中，便于处理
        cat $patchFile | tail -n +$(($begin+1)) > $nextfile
        #### 逐行解析，累加需要的行数
        cat $nextfile  | while read lineForEnd
        do
            local checkNextMark=`echo $lineForEnd | grep -F "diff --git a/"`
            if [ ! -z $checkNextMark ];then
                break;
            fi
            end=$(($end+1))
        done
        (
        cat<<EOF
sed -n '${begin},${end}p' $patchFile >> $outfile
EOF
        ) >  $cmd_file
        bash $cmd_file

        break;
    done
    echo "Gen : $outfile"
}

# 删除补丁中的新增文件部分
function git-patch-remove-new-file ()
{
    local patchFile=$1
    if [ -z "$patchFile" ]; then
        echo "need : patchFile-from-'git diff/show/format-patch'"
        return 1
    fi

    local DATE=$(date "+%Y%m%d%H%M%S")
    local output="$patchFile.remove.new"
    cp /dev/null $output

    local i=1
    local revert=0
    ## All File inline
    cat $patchFile  | while IFS= read -r line
    do
        # 检测当前行的下一行是否为 'new file mode'
        # 打印下一行
        local isStartSeciton=`echo $line  |grep "^diff --git a"`
        #local isCurFileSeciton=`echo $line  |grep "new file mode"`
        local nextLine=`tail -n+$(($i+1)) $patchFile |head -1`
        local isNewFileSeciton=`echo $nextLine  |grep "new file mode"`
        # 判断是否是补丁片段的开始
        if [ ! -z "$isStartSeciton"  ];then
            # 如果这个片段是新的
            if [ ! -z "$isNewFileSeciton" ];then
                revert=1
                echo "Remove part of `echo $line | sed "s#diff --git a/##" | awk '{print$1}'`"
            else
                revert=0
                #echo stop $i
            fi
        fi
        if [ 0 -eq $revert ];then
            echo "$line" >> $output
        fi
        i=$(($i+1))
    done
    echo "gen $output"
}

# 打印'git show'这种补丁中的头部提交信息
function git-show-patch-commit-info ()
{
    local patchFile=$1
    if [ -z "$patchFile" ]; then
        echo "need : patchFile from 'git show'"
        return 1
    fi

    local diff=""
    cat $patchFile | while read line
    do
        diff=`echo "$line" | grep -F "diff --git"`
        if [ ! -z $diff ];then
            break
        fi
        echo "$line"
    done
}

