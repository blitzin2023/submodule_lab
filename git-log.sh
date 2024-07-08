#!/bin/sh

# 查看git仓库下的提交记录
alias gh="git log -- -p"

alias  gl="git log --graph --all --decorate=short"
alias gla="git log --date=iso --name-status"
alias gll="git log --graph --decorate --pretty=oneline --abbrev-commit"
## 对齐的git 分支 log
#git-log-branch
function glb ()
{
    local   mode="$1"
    local      x=${1-16}
    local length=`expr $x + 8`

    git config --global alias.treex

    if [ "$mode" = "" ]; then
        mode="normal"
    fi

    if [ "$mode" = "all" ]; then
        # commit-id   date   tittle  author ref-date
        git log  --color \
            --graph --pretty=format:"%>|($length)%C(cyan)%h%Creset - %C(cyan)%ad%Creset %<(80,trunc)%s   %C(cyan)%>(20,trunc)%an - %Cgreen%>(12)%cr%Creset" \
            --date=format:%Y.%m.%d
    fi
    if [ "$mode" = "normal" ]; then
        length=18
        # commit-id   date   tittle  author ref-date
        git log  --color \
            --graph --pretty=format:"%>|($length)%C(cyan)%h%Creset - %C(cyan)%ad%Creset %<(80,trunc)%s   %C(cyan)%>(20,trunc)%an" \
            --date=format:%Y.%m.%d
    fi
}

## 列出所有提交的hash-id
function git-log-list-commits-id ()
{
    # %h 缩短的commit hash , %p 缩短的 parent hashes
    #git log --pretty=format:"%h : %p"
    git --no-pager log --pretty=format:"%h%n" "$@"
}

## 列出所有提交的hash、作者以及提交标题
function git-log-list ()
{
    git --no-pager log --pretty=tformat:"[%h] : [%cN] : %s" "$@"
}

## 显示某次提交，包括对应的文件
function git-show-commit-file ()
{
	gla -n 1 "$@"
}

function git-log-list-with-file-list ()
{
    git-log-list --name-only "$@"
}

function git-log-list-help ()
{
cat <<EOF
git 用各种 placeholder 来决定各种显示内容：

    %H: commit hash
    %h: 缩短的 commit hash
    %T: tree hash
    %t: 缩短的 tree hash
    %P: parent hashes
    %p: 缩短的 parent hashes
    %an: 作者名字
    %aN: mailmap 的作者名字 (.mailmap 对应，详情参照git-shortlog或者git-blame)
    %ae: 作者邮箱
    %aE: 作者邮箱 (.mailmap 对应，详情参照git-shortlog或者git-blame)
    %ad: 日期 (--date= 制定的格式)
    %aD: 日期, RFC2822 格式
    %ar: 日期, 相对格式 (1 day ago)
    %at: 日期, UNIX timestamp
    %ai: 日期, ISO 8601 格式
    %cn: 提交者名字
    %cN: 提交者名字 (.mailmap 对应，详情参照git-shortlog或者git-blame)
    %ce: 提交者 email
    %cE: 提交者 email (.mailmap 对应，详情参照git-shortlog或者git-blame)
    %cd: 提交日期 (--date= 制定的格式)
    %cD: 提交日期, RFC2822 格式
    %cr: 提交日期, 相对格式 (1 day ago)
    %ct: 提交日期, UNIX timestamp
    %ci: 提交日期, ISO 8601 格式
    %d: ref 名称
    %e: encoding
    %s: commit 信息标题
    %f: sanitized subject line, suitable for a filename
    %b: commit 信息内容
    %N: commit notes
    %gD: reflog selector, e.g., refs/stash@{1}
    %gd: shortened reflog selector, e.g., stash@{1}
    %gs: reflog subject
    %Cred: 切换到红色
    %Cgreen: 切换到绿色
    %Cblue: 切换到蓝色
    %Creset: 重设颜色
    %C(...): 制定颜色, as described in color.branch.* config option
    %m: left, right or boundary mark
    %n: 换行
    %%: a raw %
    %x00: print a byte from a hex code
    %w([[,[,]]]): switch line wrapping, like the -w option of git-shortlog.  shortlog
EOF
}

## 判断提交点是否合理
function git-log-is-commit-ok ()
{
    ## 提交点
    #local commitId=$1
    local absCommitId=`git --no-pager log --pretty=format:"%h" -n1 $1`
    if [ -z "$absCommitId" ]; then
        return 1
    fi
    git --no-pager log --pretty=format:"%h" HEAD | grep $absCommitId > /dev/null
    return $?
}

## 获取 某次历史提交中的所有文件
## 输出文件会保持对应的目录结构
function git-dirlog-dump() {
    git-dump-dirlog "$@"
}
export DIRLOG_INFO_FILENAME=1.commit-info.txt
export DIRLOG_PATCH_FILENAME=2.commit-full.patch
export DIRLOG_ACTION_FILENAME=3.commit-other-action.sh

# 将某个提交点中对应的改动导出（包括复制、改名、删除等的修改，会被保存为脚本）
function git-dump-dirlog() {
    ## 提交点
    local commitId=$1
    ## 输出目录
    local output=$2

    if [ -z "$commitId" -o -z "$output" ]; then
        echo "need : commitId outputPath"
        return 1
    fi
    git-log-is-commit-ok $commitId || return 1

    #local file_list=/tmp/.files.git.log.$$.$!.list
    local _cmd=/tmp/.$$.dump.log
    rm -rf ${output}/${DIRLOG_ACTION_FILENAME}
    bash <<EOF
    gitROOT=`git rev-parse --show-toplevel 2>/dev/null`
    if [ -z "\$gitROOT"  ]; then
        exit 1
    fi
    cd \$gitROOT

    fpath=""
    fname=""
    git --no-pager log -n 1  --name-status --pretty=tformat:"" $commitId | while read line
    do
        status=\`echo \$line | awk '{print\$1}' \`
        file=\`echo \$line | awk '{\$1="";print\$0}' \`
        #echo "[\$status] [\$file]"
        fpath=\`dirname \$file\`
        fname=\`basename \$file\`

        case \$status in
            A|M )
                mkdir -p ${output}/\${fpath}
                ffile=\`echo \$file | sed 's/^[ \t]*//g'\`
                git show ${commitId}:\$ffile > ${output}/\${fpath}/\${fname}
                ;;
            C* )
                newdir=\`echo \$file | awk '{\$1="";print\$0}' \`
                echo "mkdir -p \`dirname \$newdir\` " >> ${output}/${DIRLOG_ACTION_FILENAME}
                echo "cp -vrf \$file" >> ${output}/${DIRLOG_ACTION_FILENAME}
                ;;
            R* )
                newdir=\`echo \$file | awk '{\$1="";print\$0}' \`
                echo "mkdir -p \`dirname \$newdir\` " >> ${output}/${DIRLOG_ACTION_FILENAME}
                echo "mv -vf \$file" >> ${output}/${DIRLOG_ACTION_FILENAME}
                ;;
            D )
                echo "rm -rf \$file" >> ${output}/${DIRLOG_ACTION_FILENAME}
                ;;
        esac

    done
    if [ -f "${output}/${DIRLOG_ACTION_FILENAME}" ]; then
        sed -i '1i cd \`git rev-parse --show-toplevel 2>/dev/null\` || exit 1' ${output}/${DIRLOG_ACTION_FILENAME}
    fi

    git log $commitId -n1 > ${output}/${DIRLOG_INFO_FILENAME}
    git show $commitId    > ${output}/${DIRLOG_PATCH_FILENAME}
EOF
}

## 获取 某次历史提交中的所有文件
## 输出文件会保持对应的目录结构
function git-load-dirlog() {
    git-dirlog-load "$@"
}

# 将导出的提交点中对应的改动还原到此仓库（包括复制、改名、删除等的修改）
function git-dirlog-load() {
    ## git-dirlog-dump 的输出目录
    local dirlog=$1

    if [ ! -d "$dirlog" ]; then
        echo "need : dirlog-outputPath-from-dump"
        return 1
    fi
    git-log-is-commit-ok $commitId || return 1
    abdirlog=`cd $dirlog; pwd`

    local _cmd=/tmp/.$$.dump.log
    bash <<EOF
    gitROOT=`git rev-parse --show-toplevel 2>/dev/null`
    if [ -z "\$gitROOT"  ]; then
        return 1
    fi
    cd \$gitROOT
    # 尝试打patch
    echo "[1/3] Trying apply patch: ${DIRLOG_PATCH_FILENAME}"
    git apply  ${dirlog}/${DIRLOG_PATCH_FILENAME} && { echo "[3/3] Done"; exit 0; }
    echo "[1/3] Incompatible patch."

    echo "[2/3] Running action-script."
    # 首先执行action脚本
    if [ -f "${dirlog}/${DIRLOG_ACTION_FILENAME}" ]; then
        bash ${dirlog}/${DIRLOG_ACTION_FILENAME}
    fi
    echo "[2/3] Ran action-script."

    echo "[3/3] Trying replace file with dirlog."
    find $abdirlog -type f | grep -v $DIRLOG_INFO_FILENAME | grep -v $DIRLOG_PATCH_FILENAME| grep -v $DIRLOG_ACTION_FILENAME| while read line
    do
        file=\`echo \$line | sed 's#$abdirlog/##g'\`
        cp -rvf \$line \$file
    done
    echo "[3/3] Done"
EOF
}

# 主动回收git资源
function git-log-resize-this-repo () {

    cat << EOF
WARN : 即将缩减仓库大小，当前所有提交都不会受影响。
       但是，git reflog的有关记录会被清空，确定吗？
       输入 [y] 继续
EOF
    read answer
    if [ "$answer" != 'y' ]; then
        return;
    fi
    local delay_time=3

    for last_time in {1..$delay_time}
    do
        echo "${last_time}/${delay_time}秒后执行。"
        sleep 1;
    done

    bash <<EOF
    gitROOT=`git rev-parse --show-toplevel 2>/dev/null`
    if [ -z "\$gitROOT"  ]; then
        return 1
    fi
    cd \$gitROOT

    echo "当前git仓库大小为"
    du --max-depth=1 -h .git  | tail -n1

    rm -rf .git/refs/original/
    #echo 'rm -rf <TOP>/.git/refs/original/'

    git reflog expire --expire=now --all
    #echo 'git reflog expire --expire=now --all'

    git fsck --full --unreachable
    #echo 'git fsck --full --unreachable'

    git repack -A -d
    #echo 'git repack -A -d'

    git gc --aggressive --prune=now
    #echo 'git gc --aggressive --prune=now'

    echo "完成，git仓库大小为"
    du --max-depth=1 -h .git  | tail -n1
EOF

}
