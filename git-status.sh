#*  @brief        根据git status 的列表有关的快捷命令

#!/bin/sh
## 下列的函数都是围绕 git status -s 这样格式生成的列表来进行操作的
function git-s-need-list ()
{
    echo "Need a file list form like the list made from [git status -s]"
    echo "Using [git status -s] for make a list, or 'git-s'/'git-s-uno'"
}

function git-s-do-action ()
{
    local FILE_LIST=$1
    local GIT_CMD=$2
    #local LOOP_CMD=$3
    local HERE=`pwd`
    local FILE_TEMP=/tmp/.$$.$!.git

    if [ -z "$FILE_LIST" ]; then
        git-s-need-list
		return 1
	fi

    if [ -z "$GIT_CMD" ]; then
        echo "Need a command of git, e.g. : 'git add'"
		return 1
	fi

    git-root

    echo "$FILE_TEMP" #debug
    echo "#!/bin/bash"  >  $FILE_TEMP
    echo -n "$GIT_CMD " >> $FILE_TEMP

    local flag=0
    cat $FILE_LIST | while read line
    do
        local file=`echo $line | awk '{printf$2}'`
        if [ -z "$file" ]; then
            continue
        fi
        flag=1

        echo "$file"
        echo -n " $file" >> $FILE_TEMP
    done
    if [ $flag -ne 0 ]; then
		bash $FILE_TEMP
	fi
    rm $FILE_TEMP -rf
    cd $HERE
}

# 根据 列表 进行 git add
function git-s-add ()
{
    local FILE_LIST=$1

    git-s-do-action $FILE_LIST 'git add'
    #git add `cat $FILE_TEMP`
}

# 根据 列表 撤销 git add
function git-s-unadd ()
{
    local FILE_LIST=$1

    git-s-do-action $FILE_LIST 'git rm --cached -r'
    #git rm --cached `cat $FILE_TEMP` -r
}

# git rm
function git-s-rm ()
{
    local FILE_LIST=$1

    git-s-do-action $FILE_LIST 'git rm -r'
    #git rm `cat $FILE_TEMP` -r
}

function git-s-back ()
{
    local FILE_LIST=$1
    local HERE=`pwd`

    if [ -z "$FILE_LIST" ]; then
        git-s-need-list
		return 1
	fi

    git-root

    cat $FILE_LIST | while read line
    do
        local file=`echo $line | awk '{printf$2}'`
        if [ -z "$file" ]; then
            continue
        fi

		echo "$file"
        bak $file
    done
    cd $HERE
}

function git-s-recover ()
{
    local FILE_LIST=$1

    git-s-do-action $FILE_LIST 'git checkout'
    #git checkout `cat $FILE_TEMP`
}

# 生成 操作 所需的 列表
function git-s-list ()
{
    local PATH_OUTPUT=$1
    local GIT_TOP=`git rev-parse --show-toplevel 2>/dev/null`
    local HERE=`pwd`
    if [ -z "$GIT_TOP" ]; then
        echo "Not in git repository."
		return 1
	fi
    if [ -z "$PATH_OUTPUT" ]; then
        echo "Assign a path for output."
		return 1
	fi
    local paa=`dirname $PATH_OUTPUT`
    local bf=`basename $PATH_OUTPUT`
    mkdir -p $paa
    local DIST=`cd $paa; pwd`

    cd $GIT_TOP
    git status -s  >  $DIST/${bf}
    cd $HERE
    echo "Made [$PATH_OUTPUT]"
}

function git-s-uno-list ()
{
    local PATH_OUTPUT=$1
    local GIT_TOP=`git rev-parse --show-toplevel 2>/dev/null`
    local HERE=`pwd`
    if [ -z "$GIT_TOP" ]; then
        echo "Not in git repository."
		return 1
	fi
    if [ -z "$PATH_OUTPUT" ]; then
        echo "Assign a path for output."
		return 1
	fi
    local paa=`dirname $PATH_OUTPUT`
    local bf=`basename $PATH_OUTPUT`
    mkdir -p $paa
    local DIST=`cd $paa; pwd`

    cd $GIT_TOP
    git status -s -uno >  $DIST/${bf}
    cd $HERE
    echo "Made [$PATH_OUTPUT]"
}

function git-s ()
{
    git-s-list $1
}

function git-s-uno ()
{
    git-s-uno-list $1
}

# 根据 列表备份 git 改动
function git-s-env-back ()
{
function git-s-env-back_usage ()
{
    local funname=$1
    local err_state=$2
cat <<EOF
usage: 
  $funname Git_Status_List  Backup_Dir

 - 1. Git_Status_List : list made by "git status -s -[uno]."
    
 - 2. Backup_Dir : The Dir where saves as Backup Env.
EOF

    if [  $err_state -eq 1 ]; then
        echo "-------"
        echo "error : Not in git repository."
        return 1
	fi
    if [  $err_state -eq 2 ]; then
        echo "-------"
        echo "error : Git_Status_List is not exist."
        return 1
	fi
    if [  $err_state -eq 3 ]; then
        echo "-------"
        echo "error : output dir is exist (or not specified)."
        return 1
	fi
}
    local FILE_LIST=$1
    local DIST_O=$2
    local DEFINE_INFO_PATH_1=.path_info.1
    local DEFINE_INFO_PATH_2=.path_info.2
    local DEFINE_INFO_PATH=.path_info.in_list
    local GIT_TOP=`git rev-parse --show-toplevel 2>/dev/null`
    local HERE=`pwd`

    if [ -z "$GIT_TOP" ]; then
        git-s-env-back_usage $0 1
		return 1
	fi

    if [ -z "$FILE_LIST" ]; then
        git-s-env-back_usage $0 2
		return 1
	fi

    if [ -z "$DIST_O" ]; then
        git-s-env-back_usage $0 3
		return 1
	fi

    if [ -d "$DIST_O" ]; then
        git-s-env-back_usage $0 3
		return 1
	fi

    git-root

    # 用于 标识 这个 改动对哪个版本适用
    local GIT_BACKUP_ID=`git log  --pretty=format:"%H" -1`

    echo "Backup change:"
    echo "  From: $GIT_TOP"
    echo "  To  : $DIST_O"

    mkdir ${DIST_O} -p

    local DIST=`cd ${DIST_O}; pwd`
    local TOP_DIR=${DIST}
    local BACKUP_DIR=${TOP_DIR}
    cd $TOP_DIR
    local i=0
    cat $FILE_LIST | while read line
    do
        local file=`echo $line | awk '{printf$2}'`
        if [ -z "$file" ]; then
            continue
        fi

        i=$(($i+1))
        local FOMAT_NUMBER=`echo $i | awk '{printf("%03d\n",$0)}'`
        local BASE_FILE_NAME=`basename ${file}`
        local FILE_NAME=${FOMAT_NUMBER}.${BASE_FILE_NAME}

        mkdir  ${BACKUP_DIR}/${FILE_NAME} -p

        # 保存信息 以便于 另外的脚本处理
        ### 路径1
        echo ${GIT_TOP}/${file} >> ${BACKUP_DIR}/${FILE_NAME}/${DEFINE_INFO_PATH_1}
        ### 路径2
        echo ${GIT_TOP}/${file} >> ${BACKUP_DIR}/${FILE_NAME}/${DEFINE_INFO_PATH_2}
        ### 相对路径
        echo ${file}          >> ${BACKUP_DIR}/${FILE_NAME}/${DEFINE_INFO_PATH}
        ## 登记当前目录到工作区列表中
        echo ${FILE_NAME} >> ${BACKUP_DIR}/.list.todo

        echo ${FILE_NAME} >> ${BACKUP_DIR}/.list

        # 当前文件
        cp -vr ${GIT_TOP}/${file}  ${BACKUP_DIR}/${FILE_NAME}/${BASE_FILE_NAME}
        # 准备diffenv工作区
        ### file 1(当前的文件)
        cp -vr ${GIT_TOP}/${file}  ${BACKUP_DIR}/${FILE_NAME}/1.${BASE_FILE_NAME}
        ### file 2(git最新版本的，而不是暂存区中的, 不会破坏git区)
        cd ${GIT_TOP} ; git show HEAD:${file} > ${BACKUP_DIR}/${FILE_NAME}/2.${BASE_FILE_NAME} 2>/dev/null || echo "${file} not in repo"
        cd ${TOP_DIR}

        ## 备份(用于恢复)
        cp -vr ${BACKUP_DIR}/${FILE_NAME}/1.${BASE_FILE_NAME} ${BACKUP_DIR}/${FILE_NAME}/.bak.1.${BASE_FILE_NAME}
        cp -vr ${BACKUP_DIR}/${FILE_NAME}/2.${BASE_FILE_NAME} ${BACKUP_DIR}/${FILE_NAME}/.bak.2.${BASE_FILE_NAME}
        ## 拷贝
    done
    cp $FILE_LIST ${BACKUP_DIR}/ori.list
    cat ${BACKUP_DIR}/.list.todo | sort > /tmp/_tmp_sort
    cp /tmp/_tmp_sort ${BACKUP_DIR}/.list.todo
    cp /tmp/_tmp_sort ${BACKUP_DIR}/.list.todo.full

    ## 保存路径、GIT ID
    echo ${GIT_TOP} > $BACKUP_DIR/ori.path
    echo ${GIT_BACKUP_ID} > $BACKUP_DIR/ori.cmtid
    cd ${BACKUP_DIR}
    echo "Creating Backup Repo for This diff-env"
    git init && git add .&& git config --local user.name schips && git config --local user.email schips@123.com  && git commit -m "Backup This diff-env" > /dev/null
    cd $HERE
}

# 根据备份 还原 git 改动
function git-s-env-recover ()
{
function git-s-env-recover_usage ()
{
    local funname=$1
    local err_state=$2
cat <<EOF
usage: 
  $funname Backup_Dir

 - 1. Backup_Dir : The Dir where saves as Backup Env.
EOF
    if [  $err_state -eq 1 ]; then
        echo "-------"
        echo "error : Not in git repository."
        return 1
	fi
    if [  $err_state -eq 2 ]; then
        echo "-------"
        echo "error : Missmatch backup env."
        return 1
	fi
}
    local FROM=$1
    local GIT_TOP=`git rev-parse --show-toplevel 2>/dev/null`
    local HERE=`pwd`

    if [ -z "$GIT_TOP" ]; then
        git-s-env-recover_usage $0 1
        return 1
	fi

    if [ ! -f ${FROM}/.list  ]; then
        git-s-env-recover_usage $0 2
		return 1
	fi

    git-root

    echo "Recover change:"
    echo "  From: $FROM"
    echo "  To  : $HERE"

    local FILE_LIST=${FROM}/.list
    local TOP_DIR=${GIT_TOP}
    local GIT_BACKUP_ID=`cat ${FROM}/ori.cmtid`
    local GIT_CURR_ID=`git log  --pretty=format:"%H" -1`
    if [ ! "$GIT_BACKUP_ID" = "$GIT_CURR_ID" ]; then
		echo "-------  Waring:Commit ID NOT MATCH  -------"
		echo $GIT_BACKUP_ID
		echo $GIT_CURR_ID
	fi

    cd $FROM
    local i=0
    cat $FILE_LIST | while read line
    do
        local info=$line/.path_info.in_list
        local cont=`cat $info`
        if [ -z "$cont" ]; then
            continue
        fi
        local fl=`basename $cont`
        local dr=`dirname $cont`

        mkdir -p ${GIT_TOP}/${dr}
        \cp -vr ${line}/$fl ${GIT_TOP}/${cont}
    done
    cd $HERE
}

