#!/bin/sh

SCRIPT_PATH=$(pwd)
PROJECT_PATH="$SCRIPT_PATH/.."
XCODE_PATH=/Applications/Xcode.app
SIMULATOR_PATH=/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app

env() {
    echo """
===环境变量===
Xcode路径=$XCODE_PATH
Simulator路径=$SIMULATOR_PATH
脚本路径=$PWD
工程路径=$PROJECT_PATH
"""
}

# 重新加载工程
reopen() {
    # 清除缓存
    if [[ $1 == "clean" ]]; then
        osascript -e "tell app \"${SIMULATOR_PATH}\" to quit"
        osascript -e "tell app \"${XCODE_PATH}\" to quit"

        rm -rf ~/Library/Developer/Xcode/DerivedData
    fi

    cd $PROJECT_PATH/Example
    pod install --verbose
    find . -maxdepth 1 -name "*.xcworkspace" | xargs open

    cd $SCRIPT_PATH
}

show_menu() {
    echo """
0> 退出
Enter 重新打印

====== DoSwift CI 脚本 ======

a> 脚本
    a1> 打印环境变量

b> 工程
    b1> 重新加载工程

"""
}

env
show_menu
while read -p "请选择> " idx; do
    if [[ ${idx} == "0" ]]; then
        exit 0
    elif [[ ${idx} == "a1" ]]; then
        env
    elif [[ ${idx} == "b1" ]]; then
        reopen
    else
        show_menu
    fi
done