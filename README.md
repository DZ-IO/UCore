# UCore - 一个面向CLI的UTAU核心
## 概述
这是一个面向CLI（命令行）的UTAU核心  
至于为什么叫核心？因为本软件不带任何图形前端，依靠UST文件传导数据
## 使用说明
### 1. 下载安装：
本软件是绿色版软件，下载解压就可以
### 2. 配置：
配置文件在`UtauCore\env.ini`，下面是示例  
`;UCore配置文件`  
`;设置默认使用的声库`  
`oto=C:\Program Files (x86）\UTAU\voice\ZeW_Bata_0.1.0.191225`  
`;设置默认wavtool（工具1）`  
`tool=C:\Program Files (x86)\UTAU\wavtool.exe`  
`;设置默认resampler（工具2）`  
`resamp=C:\Program Files (x86)\UTAU\resampler.exe`  
`;设置默认缓存文件夹（可选）`  
`;cachedir=`  
`;设置输出文件（可选）`  
`;output=`  
PS1：声库、工具1、工具2 遵循UST优先逻辑（即本机已安装UST中指定的声库和引擎时默认使用UST推荐的声库和引擎）  
PS2：缓存文件夹和输出文件遵循配置文件优先逻辑  
PS3：缓存文件夹默认为`%~dp0cache`（`.\UtauCore\cache`）输出文件默认为`%CD%\temp.wav`(工程文件所在目录\temp.wav)
### 3. 使用：
`.\UtauCore\UCore[_CLI].exe <UST文件>`  
`<UST文件> UTAU的工程文件`  
`[_CLI] 启用纯CLI模式（无弹窗，适合在应用程序内调用）`   
PS：输出文件在UST同目录下
## 使用例：
1. 类似口袋歌姬的在线合成服务
2. 在游戏 OR 软件中使用UTAU的技术（类似VOCALOID SDK for Unity）
## 已知BUG&解决方案
1. 无法合成有参工程
2. 合成速度过慢
## 开发灵感
最初是因为看到了B站的[星璇の天空](https://space.bilibili.com/232240)开发的[UTAU渲染插件](https://www.bilibili.com/video/av1182545)，然后这个插件里带了个完整版UTAU。。。  
![完整版UTAU](pics\01.png)
于是我就有了把这个U干掉的想法  
由于UTAU和UST并不复杂，我断断续续花了3天搞出了第一个测试版  
然而这个测试版并不好用，比如不支持有参工程（实际上支持VEL参数）
## 开发规划
实际上UCore是[ZOSP计划](https://github.com/daze456/ZOSP)的一部分，也是个开始  
1. 开发出UTAU Core（这是我能搞出来最简单的软件）
2. 为UCore添加WebSocket功能，允许你直接使用别人电脑上的声库和引擎合成（虽然这玩应没什么用）
3. 基于UCore的WebSocket功能继续开发搞出OVSE在线虚拟歌姬编辑器