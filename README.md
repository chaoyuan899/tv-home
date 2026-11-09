# TV Home — TCL 55D6 / Android 5.1

基于 [mihirgupta0900/tv-home](https://github.com/mihirgupta0900/tv-home) 的 TCL 55D6 适配。保留壁纸、时钟、应用 Dock 和遥控器操作，支持 Android 5.1.1（API 22）及 TCL 国内版应用入口。后续再逐步加入 [tinulica/tv-home](https://github.com/tinulica/tv-home) 的功能。

本分支改为**系统原生默认桌面**，替代上一版的无障碍跳转：系统进入首页时直接启动 TV Home，原厂桌面仍保留。没有无障碍服务、开机广播跳转或新增运行时依赖。普通/TV 应用去重显示，支持中文、TCL 设置与信源，以及旧版绘图兼容处理。

仅验证 **55D6 / V8-A962T04-LF1V117 / API 22**。不刷机、不 root、不覆盖系统签名。开机 TCL 标志及系统初始化仍然存在；开机广告属于独立的固件服务，详见[适配说明](docs/tcl55d6-direct-home.md)。

## 备份与编译

先备份原桌面 `com.tcl.cyberui`、设置 `com.tcl.settings`、信源 `com.tcl.sourcemananger` 的 APK，以及包列表、禁用状态、系统设置。广告相关改动需另外保存广告服务 APK/ODEX、`/data/local/bootvideo` 和原包状态。校验文件哈希，并将备份、设备信息和签名密钥保存在自己的电脑，勿提交仓库。

这些是应用及设置回退备份，不是整机固件镜像，不包含私有应用数据、DRM 或固件分区。

macOS 需要 JDK 17、Python 3、Android SDK platform 34、build-tools 35.0.0、platform-tools。支持 `JAVA_HOME`、`ANDROID_HOME`、`BUILD_TOOLS_VERSION` 环境变量。

```bash
bash launcher/build-and-install.sh --build
bash tools/legacy-home/build.sh
bash tests/run.sh
```

生成 `launcher/build/tvhome.apk`、安装暂存用的 `tvhome-bootstrap.apk` 和 `launcher/build/legacy-home/tvhome-tools.jar`。保存私有 `launcher/debug.keystore`，以后升级必须使用同一签名。默认只编译，不操作电视。

## 安装为系统首页

开启电视 ADB，电脑与电视处于可互通的局域网。将地址替换成自己的电视 IP，备份目录必须是新目录：

```bash
"$HOME/Library/Android/sdk/platform-tools/adb" connect TV_IP:5555
python3 tools/install-tcl-home.py --serial TV_IP:5555 \
  --backup-dir /absolute/path/to/new-private-backup --select
```

脚本检查固件，备份现有桌面 APK 和首页配置，校验备份后安装。首次安装先放入同签名普通应用，再升级为原生 HOME。临时修改 `sys.currentlauncher`、`persist.tcl.debug.installapk`、`persist.tcl.installapk.enable`，安装后恢复各自原值；设备必须明确返回 `Success`。选定首页后再核对系统默认组件。

省略 `--select` 可只升级而不主动重新选择首页；已有默认设置仍可能生效。安装原生 HOME 不是完全隔离的“预览模式”。连接中断导致恢复失败时，使用备份的 `properties.json` 恢复属性，空值应恢复为空字符串。

## 回退

- 电视上：**桌面模式 → 返回原厂桌面**，关闭本应用的 HOME 入口，保留两边应用及数据。
- 电脑上：`bash tools/restore-tcl-home.sh TV_IP:5555`，验证原厂首页可用，关闭新入口并明确设回 TCL。原厂桌面可能按原设置打开上次信源。
- 再次使用：打开应用列表中的 TV Home，选择 **桌面模式 → 使用 TV Home**。若出现系统选择框，选 TV Home 和“始终”。也可重新执行安装脚本的 `--select`。

回退脚本需要先编译 `tools/legacy-home/build.sh`，或用 `HELPER_JAR` 指定已有 helper。恢复原厂桌面与恢复广告服务是独立操作。

## 验证与定制

[验证记录](docs/tcl55d6-validation.md) 区分真机结果及尚未验证的场景。`tests/run.sh --device` 运行五项实际设备检查；使用 `ADB_SERIAL` 指定电视。测试 APK 也需满足电视安装策略，测试完移除测试包。

Dock、隐藏应用和信源包名在 [config.xml](launcher/res/values/config.xml) 中配置。仓库原有 `setup.sh`、`tools/disable.sh` 和 Google TV 精简清单来自上游，**不属于本型号的安装流程**。

## License and credits

代码遵循上游 MIT 许可，见 [LICENSE](LICENSE)。壁纸保留原作者和各自许可证，见 [WALLPAPER-CREDITS.md](launcher/WALLPAPER-CREDITS.md)。上游项目受到 [Gathin23/tv-vibehack](https://github.com/Gathin23/tv-vibehack) 启发。
