# OPPO 每日签到助手（OPPO Daily Check-in）

一款本地优先、零联网权限、严格权限隔离的原生 Android（Kotlin + Jetpack Compose）应用，用于在每天指定时间（默认本地时间 **09:00**）协助完成 **OPPO 商城 / OPPO Store** 每日会员积分签到。

---

## 1. 核心特性与安全边界

- **单一职责与确定性状态机**：仅执行「启动选定 OPPO 商城 → 点击“会员” → 进入“我的积分” → 检查是否已签到 → 仅点击一次“签到” → 验证结果」流程。
- **严格禁止越界操作**：绝不下单、绝不兑换积分、绝不进入支付页、绝不修改账号信息、绝不点击无关按钮、结果不确定时绝不重复点击签到。
- **无障碍权限严格隔离**：
  - 在配置层与运行时动态将 `AccessibilityServiceInfo.packageNames` 锁定为用户选定的**单个 OPPO 应用包名**。
  - 每次处理事件均执行三重校验：事件包名校验、活动窗口根包名校验、会话激活状态校验。
  - 禁用手势模拟（`canPerformGestures="false"`）、不截屏、不记录完整控件树。
  - 跳转无障碍设置前强制展示应用内隐私声明并要求用户显式同意。
- **零联网与隐私保护**：`AndroidManifest.xml` 不声明 `INTERNET`、`QUERY_ALL_PACKAGES`、`SYSTEM_ALERT_WINDOW` 等敏感权限；无任何统计 SDK、广告或远程控制。
- **诚实应对 Android 平台限制**：
  - **路径 A（尽力自动执行）**：定时触发时若设备处于亮屏且已解锁状态，通过标准系统 API 尝试启动目标应用并执行自动签到。
  - **路径 B（安全通知回退）**：若设备锁屏、息屏、无障碍未开启或系统拦截后台启动，绝不绕过锁屏或使用全屏弹窗，而是发送通知（标题 `OPPO Daily Check-in`，内容 `It's time for your daily OPPO points check-in.`，操作按钮 `Start Check-in`），由用户点击后安全拉起签到流程。

---

## 2. 项目结构

```text
oppo-daily-checkin/
├── settings.gradle.kts
├── build.gradle.kts
├── gradle.properties
├── gradle/wrapper/gradle-wrapper.properties
├── README.md
├── BUILD_REPORT.md
├── TESTING_REPORT.md
└── app/
    ├── build.gradle.kts
    ├── proguard-rules.pro
    └── src/
        ├── main/
        │   ├── AndroidManifest.xml
        │   ├── res/
        │   │   ├── drawable/ic_launcher_background.xml
        │   │   ├── drawable/ic_launcher_foreground.xml
        │   │   ├── mipmap-anydpi-v26/ic_launcher.xml
        │   │   ├── mipmap-anydpi-v26/ic_launcher_round.xml
        │   │   ├── values/strings.xml
        │   │   ├── values/themes.xml
        │   │   └── xml/accessibility_service_config.xml
        │   └── java/com/oppo/checkin/
        │       ├── CheckinApplication.kt
        │       ├── data/CheckinModels.kt
        │       ├── data/CheckinRepository.kt
        │       ├── notification/NotificationHelper.kt
        │       ├── scheduler/AlarmScheduler.kt
        │       ├── scheduler/DailyAlarmReceiver.kt
        │       ├── scheduler/SystemEventReceiver.kt
        │       ├── automation/UiNodeInspector.kt
        │       ├── automation/CheckinStateMachine.kt
        │       ├── service/CheckinAccessibilityService.kt
        │       └── ui/
        │           ├── AppDiscovery.kt
        │           ├── MainViewModel.kt
        │           ├── StartCheckinActivity.kt
        │           ├── MainActivity.kt
        │           └── DashboardScreens.kt
        ├── test/java/com/oppo/checkin/
        │   ├── AlarmSchedulerTest.kt
        │   └── CheckinStateMachineTest.kt
        └── androidTest/java/com/oppo/checkin/
            └── MainActivityUiTest.kt
```

---

## 3. 构建与安装指南（需本地 Android SDK 与 JDK 17）

### 3.1 环境要求
- JDK 17
- Android Studio（Ladybug 或更高版本）或 Android SDK（`compileSdk 35` / `build-tools 35.0.0`）
- Gradle 8.7+

### 3.2 编译 Debug APK 与运行测试
在项目根目录执行：
```bash
# 如首次使用尚未生成 wrapper jar，可在 Android Studio 中打开项目自动同步，或使用本机 gradle：
gradle wrapper --gradle-version 8.7

./gradlew clean
./gradlew test
./gradlew assembleDebug
```
构建成功后，Debug APK 位于：
`app/build/outputs/apk/debug/app-debug.apk`

计算 APK SHA-256 校验和：
```bash
sha256sum app/build/outputs/apk/debug/app-debug.apk
```

安装到已开启 USB 调试的 OPPO 手机：
```bash
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

### 3.3 Release 签名配置说明
本项目**未**内置任何私钥。如需构建正式发布版：
1. 生成本地签名密钥（妥善保管，切勿提交到代码库）：
   ```bash
   keytool -genkey -v -keystore release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias oppo_checkin
   ```
2. 在 `app/build.gradle.kts` 中通过本地 `keystore.properties` 或环境变量配置 `signingConfigs.release`，然后运行 `./gradlew assembleRelease`。

---

## 4. 权限配置指南

1. **选择目标应用**：打开「OPPO 每日签到助手」→ 概览页点击「选择应用」→ 选择设备上的 **OPPO 商城 / 欢太商城**。
2. **开启无障碍服务**：点击无障碍权限右侧「前往设置」→ 阅读并点击「同意并前往设置」→ 在系统「无障碍 / 已下载的应用」中找到「OPPO 每日签到助手」并开启。
3. **开启精确闹钟（Android 12+）**：点击「闹钟与提醒」→ 授权允许设置精确闹钟。若不授权，应用将明确提示并使用非精确回退调度。
4. **开启通知权限（Android 13+）**：点击「开启通知」，确保锁屏或后台受限时可收到 `Start Check-in` 提醒。

---

## 5. OPPO ColorOS 后台与电池设置指南

1. **允许后台运行**：系统设置 → 应用管理 → OPPO 每日签到助手 → 耗电管理 → 开启「允许完全后台行为」。
2. **允许自启动**：应用详情 → 自启动/权限管理 → 开启「允许自启动」（用于设备重启后恢复每日闹钟）。
3. **允许通知**：应用详情 → 通知管理 → 开启「允许通知」及「每日签到提醒」渠道。
4. **关闭激进电池优化**：系统设置 → 电池 → 更多电池设置 → 电池优化 → 将「OPPO 每日签到助手」设为「不优化」。

---

## 6. 真机集成测试步骤（15 项验收清单）

1. **首次安装**：安装 APK 并启动，确认界面为简体中文，默认时间为 `09:00`，开关默认关闭。
2. **应用发现**：点击「选择应用」，确认可列出已安装的可启动应用并优先标记 OPPO/欢太应用。
3. **目标包名锁定**：选定 OPPO 商城后，在「概览」确认显示正确的包名与应用名称。
4. **无障碍声明与开启**：点击「前往设置」，确认先弹出隐私声明弹窗，同意后才跳转系统无障碍设置。
5. **精确闹钟权限**：在 Android 12+ 设备上授权「闹钟与提醒」，确认状态变为「已授权」。
6. **通知权限**：在 Android 13+ 设备上授权通知权限，确认状态变为「已授权」。
7. **手动测试执行**：点击「立即测试签到」，观察应用自动启动 OPPO 商城并完成「会员 → 我的积分 → 签到 → 验证」。
8. **定时自动执行**：将时间设为当前时间后 2 分钟，保持亮屏解锁等待触发，确认自动执行并记录历史。
9. **锁屏状态测试**：将时间设为当前时间后 2 分钟并锁定屏幕，确认不会绕过锁屏，且发送含 `Start Check-in` 按钮的通知；解锁后点击通知可拉起签到。
10. **设备重启恢复**：开启定时后重启手机，重启完成后打开助手，确认下次执行时间已自动恢复。
11. **目标应用未运行测试**：彻底划掉 OPPO 商城后台进程后执行测试，确认可正常冷启动并完成签到。
12. **无障碍权限被收回**：在系统设置中关闭无障碍权限后触发测试，确认安全停止并提示「权限不足」。
13. **精确闹钟权限被收回**：在系统设置中撤销精确闹钟权限，确认首页明确提示「非精确回退模式，时间可能有延迟」。
14. **无网络状态测试**：开启飞行模式后测试签到，确认遇到网络异常提示时安全停止并标记「需要手动操作」。
15. **今日已签到幂等测试**：同一天内再次点击「立即测试签到」，确认识别为「今日已签到」且绝不重复点击。

---

## 7. 已知限制

- 受限于 Android 10 及以上系统的后台启动 Activity 限制，以及各厂商 ColorOS 的后台管控策略，**当设备处于锁屏、息屏或系统禁止后台弹窗时，无法静默拉起 OPPO 商城**；此时会通过安全通知提醒用户手动一键启动。
- 若 OPPO 商城版本更新导致界面文案大幅调整，需在「设置与指南」中调整对应的界面识别标签别名。
