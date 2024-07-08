#*  @brief        Git 的基础操作
#!/bin/sh


#Git about
alias gls="git ls-files"
alias  gs="git status"
alias gsn="git status -uno" # No untracked 不显示未跟踪文件(无版本的文件)
alias gsu="git status -u"   # untracked 显示未跟踪文件(无版本的文件)
alias gb="git branch"
alias gc="git clone"
alias gd="git diff"
alias gc="git clone"
function gam() { git commit -a -m $@ ;} # git add commit
alias gad="git add ."
alias gpl="git pull"
alias gpu="git push"
alias gcm="git commit"

## git clone quick
## 在用git clone下载一些比较大的仓库时，经常会遇到由于仓库体积过大，网络也不稳定，导致下了半截就中断了，可以参考如下的下载方法。
##  先用创建一个空目录，然后用git init初始化，然后用git remote add添加远程仓库，
##  紧接着，用git fetch --depth=1现在想要的分支，
## 等下载完毕后再使用git fetch --unshallow下载全部的git历史。
function gcq ()
{
    # 下载地址
    local url=$1
	# 分支
    local branch=$2

	if [ -z "$url" ];then
        echo "need : url [branch]"
    fi
	if [ -z "$branch" ];then
        branch="master"
    fi
    local last=${url##*/}
    local bare=${last%%.git}

    if [ ! -d "$bare" ];then
        bash <<EOF
        mkdir ${bare} || exit 1
        cd ${bare} || return 1
        git init
        git remote add origin $url
        echo ""
        echo "[1/2] Get branch [$branch], newest version..."
        git fetch origin $branch --depth=1 || exit 1
        echo ""
        echo "[2/2] Get branch [$branch], total commit history..."
        git fetch origin $branch --unshallow || (echo "Error when 'git fetch origin $branch --unshallow', try it by manual maybe."; exit 1)
EOF
        ret=$?
        if [ $ret -ne 0 ];then
            rm ${bare} -rf
            echo "[Err] failed when get [${bare}] "
            return $ret
        fi
    fi
    echo "[OK] Cloned [${bare}] "
}

function gc-quick ()
{
    gcq "$@"
}

function git-clone-quick ()
{
    gcq "$@"
}

## 还原所有文件(快速还原，比 "gad && git reset --hard HEAD" 快)
function git-reset-all ()
{
    local here=`pwd`
    local DATE=$(date "+%Y%m%d%H%M%S")
    local FILE_LIST=/tmp/.git_statuas_log${DATE}
    local cmd_bat=/tmp/.cmd.bat.${DATE}
    local cmd_flag=0
    git-root
    git reset HEAD --hard
    git status -s > $FILE_LIST
    echo    "#!/bin/bash" > $cmd_bat || return $?
    echo -n "rm -rf"     >> $cmd_bat

    cat $FILE_LIST | while read line
    do
        local file=`echo $line | awk '{printf$2}'`
        local result=`echo $line|awk '{printf$1}'| grep "??"`
        if [ ! -z "$result" ]; then # 判断是否是未跟踪文件
            #rm $file -rf
            echo -n " $file" >> $cmd_bat
            cmd_flag=1
        else
            mkdir `dirname $file` -p
            git show HEAD:$file > $file
            #git add $file
        fi
    done
    if [ $cmd_flag -ne 0 ]; then
		bash $cmd_bat
	fi
    rm -rf $cmd_bat
    #git reset HEAD --hard
    rm $FILE_LIST
    cd $here
}

## 还原所有跟踪文件
function git-reset-staged ()
{
    local here=`pwd`
    local DATE=$(date "+%Y%m%d%H%M%S")
    local TMP_PATCH=$here/staged-${DATE}.patch
    local FILE_LIST=/tmp/.git_statuas_log${DATE}
    local cmd_bat=/tmp/.cmd.bat.${DATE}
    local cmd_flag=0
    git-root
    git status -s > $FILE_LIST
    echo    "#!/bin/bash" > $cmd_bat || return $?
    echo -n "git add"    >> $cmd_bat

    cat $FILE_LIST | grep -v "??" | while read line
    do
        local gstatus=`echo $line | awk '{printf$1}'`
        local file=`echo $line | awk '{printf$2}'`
        echo -n " $file" >> $cmd_bat
        cmd_flag=1
    done
    if [ $cmd_flag -ne 0 ]; then
        bash $cmd_bat
    fi
    rm -rf $cmd_bat
    git diff  HEAD > $TMP_PATCH
    git reset HEAD --hard  && rm $FILE_LIST
    echo "Gen patch :[`basename $TMP_PATCH`]"
    cd $here
}

# Git-svn about
alias gsvn="git svn clone"
alias gcs="git svn clone"
alias gpls="git svn rebase" # git pull
alias gplssa="git stash && git svn rebase && git stash apply"  # 解决合并冲突
alias gpus="git svn dcommit" # git push
alias gpussa="git stash && git svn dcommit && git stash apply" # 解决合并冲突
#alias ga="git add" # already had

function git-root() {
    local gitROOT=`git rev-parse --show-toplevel 2>/dev/null`
    if [ -z "$gitROOT"  ]; then
        return 1
    fi
    cd $gitROOT
}

function git-rebase-til() {
    local allCount=`git --no-pager log --pretty=tformat:"%H" | wc -l`
    local maxCount=$(($allCount-1))
    if [ $# -ne 1 ]; then
		echo "Need a index start from HAED"
        return
	fi
    local index=1
    if [ $1 -lt $maxCount  ]; then
        index=$1
	else
        index=$maxCount
    fi
    echo "git rebase -i HEAD~$index --autostash --interactive"
    git rebase -i HEAD~$index --autostash --interactive
}

function git-to-oldest() {
    local initCID=`git --no-pager log --pretty=tformat:"%H" | tail -n 1`
    git reset --hard $initCID
}

## 从某个提交点（默认从第一个提交点）重新拉取代码
function git-repull() {
    local here=`pwd`
    #local initCID=`git --no-pager log --pretty=tformat:"%H" | tail -n 1`
    local commitId="$1"
    ## 如果没提供提交点，那么从第一个提交点开始pull
    if [ -z "$commitId"  ]; then
        commitId=`git --no-pager log --pretty=tformat:"%H" | tail -n 1`
    fi
    git-log-is-commit-ok $commitId || return 1
    bash <<EOF
    gitROOT=`git rev-parse --show-toplevel 2>/dev/null`
    if [ -z "\$gitROOT"  ]; then
        exit 1
    fi
    cd \$gitROOT
    git reset --hard $commitId
    echo "Pull code from [$commitId]."
    git pull --force origin master:master
EOF
}

 #try git clone 避免重复下载
function tgc () {
    local url=$1
    #local last=`basename $1`
    local last=${url##*/}
    local bare=${last%%.git}
    [ ! -d "$bare" ] && git clone "$url"
    echo "[OK] Cloned [${bare}] "
}

function git-try-clone () {
    tgc "$@"
}

# 向后复位
function git-backward-reset ()
{
    local commitId="$1"
    git-log-is-commit-ok $commitId || return 1

    git reset --hard $commitId;
}

# 向后复位（clean）
function git-backward-reset-clear ()
{
    local commitId="$1"
    local here=`pwd`
    git-root || return 1
    git-log-is-commit-ok $commitId || return 1

    git-reset-all || return 1
    git reset --hard $commitId;
    cd $here
}

# 列出git当前目录下跟踪的文件和目录（只打印第一深度的文件和目录）
function git-ls-track-cur-dir-smart ()
{
    local branch="$1"
    if [ -z "$branch" ]; then
        branch="master"
    fi
    local tempf1="/tmp/.$$.1"
    local tempf2="/tmp/.$$.2"

    git ls-tree -r "$branch" --name-only | awk -F'/' '{print $1}' | uniq | sort > $tempf1
    ls . -a | sort > $tempf2
    echo "Following file(s) is not tracked."
    diff $tempf1 $tempf2 | grep -v "> \." | grep -v "> \.\." | grep -E "^> |^< "
    rm $tempf1 $tempf2
}

# 列出git当前目录下跟踪的文件和目录（只打印第一深度的文件和目录）
function git-ls-track-cur-dir-1-depth ()
{
    local branch="$1"
    if [ -z "$branch" ]; then
        branch="master"
    fi

    git ls-tree -r "$branch" --name-only | awk -F'/' '{print $1}' | uniq
}

# 列出git当前目录下跟踪的文件和目录
function git-ls-track-cur-dir-all-depth ()
{
    local branch="$1"
    if [ -z "$branch" ]; then
        branch="master"
    fi

    git ls-tree -r "$branch" --name-only
}

# 列出git根目录下跟踪的文件和目录
function git-ls-track-all ()
{
    local branch="$1"
    if [ -z "$branch" ]; then
        branch="master"
    fi
    bash <<EOF
    gitROOT=`git rev-parse --show-toplevel 2>/dev/null`
    if [ -z "\$gitROOT"  ]; then
        return 1
    fi
    cd \$gitROOT
    git ls-tree -r "$branch" --name-only
EOF
}

