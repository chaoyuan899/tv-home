# TV Home — TCL 55D6 / Android 5.1

基于 [mihirgupta0900/tv-home](https://github.com/mihirgupta0900/tv-home) 的 TCL 55D6 适配分支。保留壁纸、时钟、应用 Dock 和遥控器操作，支持 Android 5.1.1（API 22）以及 TCL 国内版应用入口。后续再逐步评估 [tinulica/tv-home](https://github.com/tinulica/tv-home) 的扩展功能。

## 本分支的范围

- 原生 Java，无新增运行时依赖；最低 API 22。
- 发现普通 LAUNCHER 和 LEANBACK 应用，同一应用只显示一次。
- 配置的 Dock 应用未安装时，自动补入可用应用；刷新列表后保留焦点。
- 中文界面、TCL 设置和信源入口。
- 保留原厂桌面，通过可关闭的无障碍服务实现 Home 返回。默认关闭。
- 不 root、不刷机、不卸载系统应用，不自动执行仓库原有的精简脚本。

**固件差异：**在实测的 55D6 / `V8-A962T04-LF1V117` 上，安装包含 `android.intent.category.HOME` 的 APK 会报 `INSTALL_PARSE_FAILED_INCONSISTENT_CERTIFICATES`。同一签名、移除 HOME 声明后可正常安装。因此本分支是普通应用，不依赖 `cmd package` 或 `pm set-home-activity`。

## 先备份

至少保留原桌面 `com.tcl.cyberui`、设置 `com.tcl.settings`、信源 `com.tcl.sourcemananger` 的 APK，以及 `pm list packages -f`、禁用包列表和 `settings list system/secure/global`。先用 `pm path 包名` 查询实际路径，再 pull APK；校验 ZIP 完整性和文件哈希。不要硬编码 `/data/app` 路径。

这是桌面回退备份，不是整机镜像，不能代替私有应用数据、DRM 或固件分区备份。备份、设备信息和密钥只保存在自己的电脑。

## 编译与预览安装（macOS）

需要 JDK 17、Android SDK platform 34、build-tools 35.0.0 和 platform-tools。可以通过 `JAVA_HOME`、`ANDROID_HOME`、`BUILD_TOOLS_VERSION` 覆盖路径。

```bash
bash launcher/build-and-install.sh --build
bash tests/check-apk.sh launcher/build/tvhome.apk
# 先在电视上开启 ADB；将示例地址替换为电视的实际 IP
export ADB_SERIAL=192.168.x.x:5555
"$HOME/Library/Android/sdk/platform-tools/adb" connect "$ADB_SERIAL"
bash launcher/build-and-install.sh --install
```

默认只编译。`--install` 只安装并打开预览，不启用无障碍服务，不改变系统桌面或安装策略。输出 APK 在 `launcher/build/tvhome.apk`。本地签名文件为 `launcher/debug.keystore`，请私下保存；以后升级必须使用同一签名。

某些 TCL 固件会返回退出码 0，却输出 `install apk has be disabled`；脚本要求明确的 `Success` 才算安装成功。若遇到此限制，应先记录以下两项原值，再根据本机固件情况临时开启；装完恢复原值，原来为空的要恢复为空，不能统一设成 0：

```text
persist.tcl.debug.installapk
persist.tcl.installapk.enable
```

本分支实测临时设为 `1` 可安装。不同固件未保证适用，不需要因此恢复出厂或覆盖原厂签名。

## 启用 Home 返回 / 回退

先验证预览中的遥控器、应用、设置和信源。然后在右上角 **桌面模式 → 启用 Home 返回**，在系统无障碍设置中启用 **TV Home**。

服务仅监听 `com.tcl.cyberui` 的窗口变化，只在 `com.tcl.cyberui.MainActivity` 出现时打开 TV Home；没有屏幕内容读取能力。原厂桌面始终保留，实测通过 ADB 按 Home 后约 3–5 秒返回，期间会显示原首页，不能消除固件开机广告。其他型号/组件名不会自动接管。

部分国内 TCL 固件没有无障碍设置界面；可通过 ADB 配置 `enabled_accessibility_services` 与 `accessibility_enabled`。必须先读取并保留已有服务，只添加本应用的 `com.mihir.tvhome/com.mihir.tvhome.HomeRedirectService`，不要覆盖别人的服务配置。

- 临时返回原厂：**桌面模式 → 返回原厂桌面**，会关闭本应用的自动返回偏好。
- 紧急回退：`bash tools/restore-tcl-home.sh "$ADB_SERIAL"`。脚本调用受 DUMP 权限保护的恢复入口，关闭 Home 自动返回并打开原 TCL 桌面，随后核对前台组件。不删除 APK 或应用数据。此固件会拒绝 ADB 的 pm enable/disable，所以回退不依赖它们。
- 回退后再使用：打开 TV Home，重新选择 **桌面模式 → 启用 Home 返回**。

## 验证与定制

[验证记录](docs/tcl55d6-validation.md) 区分实测结果和未覆盖场景。APK 合约测试、纯 Java Home 策略测试以及实际电视上的 instrumentation 测试在 `tests/`。

Dock、隐藏应用、信源包名可在 [config.xml](launcher/res/values/config.xml) 修改后重编译。旧版 Android 的阴影绘制兼容处理在 `MainActivity.java`。后续功能优先考虑可在电视上调整 Dock / 隐藏应用，再评估第二个仓库的其他功能。

仓库原有 `setup.sh`、`tools/disable.sh` 和 Google TV 精简清单来自上游，**不属于本型号的安装流程**。本分支没有验证其他电视和 Android 版本。

## License and credits

代码遵循上游 MIT 许可，见 [LICENSE](LICENSE)。壁纸素材保留原作者和各自许可证，见 [WALLPAPER-CREDITS.md](launcher/WALLPAPER-CREDITS.md)。上游项目受到 [Gathin23/tv-vibehack](https://github.com/Gathin23/tv-vibehack) 启发。
