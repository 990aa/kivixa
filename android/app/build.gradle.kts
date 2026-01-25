import com.android.build.gradle.internal.api.ApkVariantOutputImpl
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing properties from key.properties or environment variables
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()

// Try loading from key.properties file first (local builds)
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Override with environment variables if present (CI builds)
System.getenv("ANDROID_KEYSTORE_PATH")?.let { keystoreProperties["storeFile"] = it }
System.getenv("ANDROID_STORE_PASSWORD")?.let { keystoreProperties["storePassword"] = it }
System.getenv("ANDROID_KEY_ALIAS")?.let { keystoreProperties["keyAlias"] = it }
System.getenv("ANDROID_KEY_PASSWORD")?.let { keystoreProperties["keyPassword"] = it }

android {
    namespace = "com.a990aa.kivixa"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // Signing configuration
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
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Use release signing config if keystore is configured, otherwise debug key
            val releaseSigningConfig = signingConfigs.findByName("release")
            if (releaseSigningConfig?.storeFile != null) {
                signingConfig = releaseSigningConfig
            }
            
            // Enable minification for release builds
            isMinifyEnabled = false  // Set to true if you want ProGuard/R8
            isShrinkResources = false
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.1.20")
    implementation("com.google.android.material:material:1.13.0")
}

val abiCodes = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 3)
android.applicationVariants.configureEach {
    val variant = this
    variant.outputs.forEach { output ->
        val abiVersionCode = abiCodes[output.filters.find { it.filterType == "ABI" }?.identifier]
        if (abiVersionCode != null) {
            (output as ApkVariantOutputImpl).versionCodeOverride = variant.versionCode * 10 + abiVersionCode
        }
    }
}
