pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        maven("https://maven.aliyun.com/repository/google")
        maven("https://maven.aliyun.com/repository/public")
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

// 签名向导没有 Flutter 的运行参数时，从本机配置读取 Key。
// 显式传入的 --dart-define / --dart-define-from-file 始终优先。
val localAmapConfig = file("../amap.local.json")
if (!gradle.startParameter.projectProperties.containsKey("dart-defines") && localAmapConfig.isFile) {
    val values = groovy.json.JsonSlurper().parse(localAmapConfig) as Map<*, *>
    val defines = values.entries.mapNotNull { (key, value) ->
        if (key is String && value is String && value.isNotBlank()) {
            java.util.Base64.getEncoder().encodeToString("$key=$value".toByteArray(Charsets.UTF_8))
        } else null
    }
    if (defines.isNotEmpty()) {
        val encodedDefines = defines.joinToString(",")
        gradle.beforeProject {
            if (!hasProperty("dart-defines")) {
                extensions.extraProperties.set("dart-defines", encodedDefines)
            }
        }
    }
}

include(":app")
