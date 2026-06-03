import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing properties from key.properties or environment variables
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

System.getenv("ANDROID_KEYSTORE_PATH")?.let { keystoreProperties["storeFile"] = it }
System.getenv("ANDROID_STORE_PASSWORD")?.let { keystoreProperties["storePassword"] = it }
System.getenv("ANDROID_KEY_ALIAS")?.let { keystoreProperties["keyAlias"] = it }
System.getenv("ANDROID_KEY_PASSWORD")?.let { keystoreProperties["keyPassword"] = it }

android {
    namespace = "com.a990aa.kivixa"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"] as String?
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
                storePassword = keystoreProperties["storePassword"] as String?
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
            }
        }
    }

    defaultConfig {
        applicationId = "com.a990aa.kivixa"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    buildTypes {
        release {
            val releaseSigningConfig = signingConfigs.findByName("release")
            if (releaseSigningConfig?.storeFile != null) {
                signingConfig = releaseSigningConfig
            }
            
            isMinifyEnabled = true  
            isShrinkResources = true
        }
    }

    packaging {
        jniLibs.pickFirsts.add("lib/*/libc++_shared.so")
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("com.google.android.material:material:1.14.0")
}

configurations.all {
    resolutionStrategy {
        force("androidx.core:core:1.13.1")
        force("androidx.core:core-ktx:1.19.0")
        force("androidx.browser:browser:1.8.0")
    }
}

val sanitizeGeneratedPluginRegistrant by tasks.registering {
    doLast {
        val registrant = file("src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java")
        if (!registrant.exists()) return@doLast

        var content = registrant.readText()
        content = content.replace(
            "flutterEngine.getPlugins().add(new dev.flutter.plugins.integration_test.IntegrationTestPlugin());",
            "final Class<?> pluginClass = Class.forName(\"dev.flutter.plugins.integration_test.IntegrationTestPlugin\");\n      flutterEngine.getPlugins().add((io.flutter.embedding.engine.plugins.FlutterPlugin) pluginClass.getDeclaredConstructor().newInstance());",
        )
        content = content.replace(
            "flutterEngine.getPlugins().add(new io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin());",
            "final Class<?> pluginClass = Class.forName(\"io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin\");\n      flutterEngine.getPlugins().add((io.flutter.embedding.engine.plugins.FlutterPlugin) pluginClass.getDeclaredConstructor().newInstance());",
        )
        registrant.writeText(content)
    }
}

tasks.matching {
    it.name == "compileDebugJavaWithJavac" || it.name == "compileReleaseJavaWithJavac"
}.configureEach {
    dependsOn(sanitizeGeneratedPluginRegistrant)
}

tasks.matching {
    it.name == "sanitizeGeneratedPluginRegistrant"
}.configureEach {
    mustRunAfter("compileFlutterBuildRelease")
}
