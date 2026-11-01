import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

// 1. Resolve from Environment Variables, 2. Properties file, 3. null
val envStorePath = System.getenv("ANDROID_KEYSTORE_PATH")
val envStorePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
val envKeyAlias = System.getenv("ANDROID_KEY_ALIAS")
val envKeyPassword = System.getenv("ANDROID_KEY_PASSWORD")

val releaseStoreFile: File? = when {
    !envStorePath.isNullOrBlank() -> File(envStorePath)
    keystoreProperties.getProperty("storeFile") != null -> {
        val path = keystoreProperties.getProperty("storeFile")
        val file = File(path)
        if (file.isAbsolute) file else rootProject.file(path)
    }
    else -> null
}

val releaseStorePassword: String? = envStorePassword ?: keystoreProperties.getProperty("storePassword")
val releaseKeyAlias: String? = envKeyAlias ?: keystoreProperties.getProperty("keyAlias")
val releaseKeyPassword: String? = envKeyPassword ?: keystoreProperties.getProperty("keyPassword")

val isReleaseSigningConfigured = releaseStoreFile != null &&
    releaseStoreFile.exists() &&
    !releaseStorePassword.isNullOrBlank() &&
    !releaseKeyAlias.isNullOrBlank() &&
    !releaseKeyPassword.isNullOrBlank()

android {
    namespace = "com.adilabs.diti"
    compileSdk = flutter.compileSdkVersion
    val envNdkVersion = System.getenv("ANDROID_NDK_VERSION")
        ?: System.getenv("ANDROID_NDK")?.let { File(it).name }
        ?: System.getenv("ANDROID_NDK_HOME")?.let { File(it).name }
    ndkVersion = if (!envNdkVersion.isNullOrBlank()) envNdkVersion else flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.adilabs.diti"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        manifestPlaceholders["appName"] = "Diti"
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
    }

    signingConfigs {
        if (isReleaseSigningConfigured) {
            create("release") {
                storeFile = releaseStoreFile
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        getByName("debug") {
            applicationIdSuffix = ".debug"
            manifestPlaceholders["appName"] = "Diti (Debug)"
        }
        release {
            if (isReleaseSigningConfigured && signingConfigs.findByName("release") != null) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                logger.warn("WARNING: No valid release keystore found. Falling back to debug signing config.")
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }

    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
