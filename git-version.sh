#!/bin/sh
#*  @brief        Git 版本相关的

# 把对应版本的文件全部导出
# git-dump-dirlog，git-version-dump 导出所有文件
# 而 git-dump-dirlog 导出局部文件
function git-version-dump () {
    local commitId=$1
    local export_dir=$2
    if [ -z "$commitId" ]; then
        echo "need : Commit-ID Export-Dir"
        return
    fi
    if [ -z "$export_dir" ]; then
        echo "need : Commit-ID Export-Dir"
        return
    fi
    git-log-is-commit-ok $commitId || return 1
    gitROOT=`git rev-parse --show-toplevel 2>/dev/null`
    bash <<EOF
    if [ -z "$gitROOT"  ]; then
        echo "You are not int a git-repo dir."
        exit 1
    fi
    mkdir -p $export_dir
    rm -rf $export_dir/.git
    cp -rf $gitROOT/.git $export_dir/.git
    cd $export_dir
    git reset --hard $commitId
EOF
}


# 创建一个带有空白readme文件的初始git仓库
# $1 :  远程仓库地址，可选
# $2 ： 提交的消息，如果为空，使用"Init Commit."
function git-init-repo-with-readme () {
    local repo_remote_url=$1
    local commit_msg=$2
    local repo_path=$3
    local commit_msg_default="Init Commit."
    local repo_path_default="./"
    if [ -z "$commit_msg" ]; then
        commit_msg=$commit_msg_default
    fi
    if [ -z "$repo_path" ]; then
        repo_path=$repo_path_default
    fi

    cat <<EOF
 Info :
        (\$1) Remote-URL is [$repo_remote_url]
        (\$2) Using [$commit_msg] as commit message.
        (\$3) Repo path is [$repo_path]
EOF
    sleep 1
    bash <<EOF
    cd $repo_path
    git init .
    touch Readme.md
    git add Readme.md -f
    git commit -m "$commit_msg"
EOF
    if [ ! -z "$repo_remote_url" ]; then
        cat >> ${repo_path}/.git/config <<EOF
[remote "origin"]
    url = $repo_remote_url
    fetch = +refs/heads/*:refs/remotes/origin/*
[branch "master"]
    remote = origin
    merge = refs/heads/master
EOF

    fi
}
