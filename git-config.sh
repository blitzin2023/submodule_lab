#*  @brief        Git 有关配置
#!/bin/sh

# 是否隐藏zsh访问 git 仓库时自动查询git-status
function git-config-zsh-hide-git-status() {
    local hide="$1"
    if [ -z $hide ];then
        echo "yes/hide, no/show"
    fi
    case $hide in
        Y*|y*|h* )
            git config --add oh-my-zsh.hide-status 1
            echo "hide git-status when zsh staying a git-repo"
            ;;
        N*|n*|s* )
            git config --add oh-my-zsh.hide-status 0
            echo "show git-status when zsh staying a git-repo"
            ;;
    esac
}

## 禁用八进制引用，以解决中文乱码问题
function git-config-disable-quotepath () {
    cat <<EOF
Disable quotepath for utf8 file name
Then, you need to change your Terminal.
    e.g. : Options->Text-> Character set : UTF-8
EOF

    git config --global core.quotepath false
}

## 忽略换行符导致的diff差异
function git-config-ignore-diff-lf-m () {
    echo "Ignore difference line feed character when git-diff"
    git config --global core.whitespace cr-at-eol
    git config --global core.atocrlf true
}

## 配置用户名以及邮箱
function git-config-name-email-local () {
    local name="$1"
    local mail="$2"
    ## 两者都为空，代表查询
    if [ -z "$name" -a -z "$mail" ]; then
        git config --local user.name
        git config --local user.email
        return 0
    fi
    ## 两者都有值，代表设置
    if [ -z "$name"  -o -z "$mail"  ]; then
        echo "need : name email"
        return 1
    fi
    echo "user.name is ${name}"
	git config --local user.name  ${name}
    echo "user.email is ${mail}"
	git config --local user.email ${mail}
}

function git-config-name-email-global () {
    local name="$1"
    local mail="$2"
    ## 两者都为空，代表查询
    if [ -z "$name" -a -z "$mail" ]; then
        git config --global user.name
        git config --global user.email
        return 0
    fi
    ## 两者都有值，代表设置
    if [ -z "$name"  -o -z "$mail"  ]; then
        echo "need : name email"
        return 1
    fi
    echo "user.name is ${name}"
	git config --global user.name  ${name}
    echo "user.email is ${mail}"
	git config --global user.email ${mail}
}

# 针对gerrit的push审核配置
function git-gerrit-config ()
{
    echo "config[remote.origin.push 'refs/heads/*:refs/for/*'] when git-push to gerrit"
    bash -v <<EOF
git config remote.origin.push 'refs/heads/*:refs/for/*'
EOF
}
function git-config-gerrit-push-remote ()
{
    git-gerrit-config
}

# 是否忽略文件模式(Chmod)更改，不带参数执行时默认忽略
# local 默认是不忽略的，而global 会被local覆盖
function git-config-file-mode-local ()
{
    #git config       --global core.filemode false
    if [ -z "$1"  ]; then
        echo "Disable filemode trace."
        echo " for enable filemode trace, use 'git-config-file-mode-local y'."
        git config       --local core.filemode false && return 0
        git config --add --local core.filemode false
    else
        echo "Enable git filemode trace."
        echo " for disable filemode trace, use 'git-config-file-mode-local'."
        git config       --local core.filemode true && return 0
        git config --add --local core.filemode true
    fi
}
function git-config-editor ()
{
    if [ ! -z "$*" ]; then
        echo "git editor is [$@]"
    fi
    git config core.editor "$@" --global || return $?
}

function git-init-config () {
    git-config-editor `mysc-cfg-get editor`
    git-config-ignore-diff-lf-m
    git-config-zsh-hide-git-status hide
    git-config-name-email-global schips schips@dingtalk.com
    git-config-disable-quotepath
}
function git-config-init () {
    git-init-config
}

