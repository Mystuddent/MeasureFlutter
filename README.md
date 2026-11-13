# 田亩通（Flutter）

一个用于练习 Flutter 的 Android/iOS 田块测量项目。首页支持高德地图、前台定位及田块边界测量；iOS 尚需在 Mac 真机上验证，尚未接入云服务器。

## 当前实现

- 首页先展示隐私提示，获得同意和前台定位权限后才加载地图。
- 实时定位、地图居中、开始/暂停/完成测量，计算面积、亩数和周长。
- 测量期间可手动添加当前位置；手动点须满足精度要求，且与上一点至少相距 0.5 米。
- 默认仅接受误差在 20 米以内的新定位点，采点间距至少 5 米；可在设置中调整。进入后台或锁屏后暂停采点。
- 完成测量后可命名并保存到本机，在右上角测量记录中点击记录可在地图上重现边界；暂不支持云端同步或编辑历史记录。
- 原始 WGS84 坐标用于面积计算，近似转换为 GCJ-02 后用于地图显示。
- 面积计算：小范围 WGS84 坐标局部投影后使用鞋带公式；亩按 `666.6666667 平方米`换算。
- 验证：`flutter analyze` 和 `flutter test`。

## 目录说明

```text
lib/
  main.dart                         应用入口和主题（含旧的演示页面）
  features/measure/amap_preview_page.dart 定位授权、地图和前台采点
  features/measure/area_calculator.dart  坐标模型、面积与周长算法
  features/measure/coordinate_transform.dart  WGS84到GCJ-02显示坐标转换
  features/measure/measurement_store.dart  本机设置与历史记录存储
  features/measure/history_page.dart  测量记录列表
test/
  widget_test.dart                  隐私提示与平台测试
  area_calculator_test.dart         面积算法测试
android/                            Android原生壳、Gradle和权限配置
ios/                                iOS原生壳、Xcode工程和权限配置
pubspec.yaml                        Dart版本、依赖和资源声明
pubspec.lock                        已解析依赖的具体版本
analysis_options.yaml               Dart静态检查规则
.vscode/settings.json               本机Flutter/Android/JDK路径，不提交到Git
```

## 开发环境

安装 Flutter SDK、Android SDK 和兼容的 JDK，然后在编辑器中打开项目根目录。将 `amap.example.json` 复制为 `amap.local.json` 并填写自己的平台 Key；本机配置和 Key 不提交到仓库。

在终端运行：

```powershell
flutter doctor -v
flutter analyze
flutter test
flutter run --dart-define-from-file=amap.local.json
flutter build apk --debug --dart-define-from-file=amap.local.json
```

Android模拟器或手机需要通过 `flutter devices` 确认可用。当前 Flutter 模板要求 Android NDK `28.2.13676358`；尚未安装时，首次 Android 构建会提示安装。iOS构建需要Mac和Xcode。
高德 Key 填入本机 `amap.local.json`，该文件不提交至 Git；客户端 Key 仍会包含在 App 中，需要在高德控制台绑定应用包名与签名。

## 下一步

1. 户外真机核对定位精度、坐标偏移和面积，并针对不同手机调整采点过滤策略。
2. 增加本地存储、记录列表、边界点编辑与云端同步。
3. 在 Mac 真机上验证 iOS 定位、地图与权限流程。
