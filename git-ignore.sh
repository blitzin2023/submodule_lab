#*  @brief        git ignore 模版
#!/bin/sh

export gitignore_ref_dir=$MYSC_ROOT_DIR/.ref/git-ignore

# 显示可用的gitignore模板
function git-ignore-help ()
{
    if [ -d $gitignore_ref_dir ]; then
        ls $gitignore_ref_dir
    fi
}

# 从 gitignore目录中挑选模板，并应用
function git-ignore-add ()
{
    local temp="$1"
    local gfile=""

    if [ -f ${gitignore_ref_dir}/${temp}.gitignore ]; then
        gfile=${gitignore_ref_dir}/${temp}.gitignore
    fi

    if [ -f ${gitignore_ref_dir}/${temp} ]; then
        gfile=${gitignore_ref_dir}/${temp}
    fi

    if [ ! -z "$gfile" ]; then
        touch .gitignore
        echo "##########################" >> .gitignore
        echo "# git-ignore-add $1 start" >> .gitignore
        cat $gfile >> .gitignore
        echo "# git-ignore-add $1 end" >> .gitignore
        echo "##########################" >> .gitignore
    else
        echo "Use [git-ignore-help] then try again."
    fi
}
