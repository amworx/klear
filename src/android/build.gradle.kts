allprojects {
    repositories {
        google()
        // Fallbacks: dl.google.com/dl/android/maven2 returns 404 for every
        // artifact on this network (filtered egress). Aliyun/Huawei mirror
        // Google Maven and are reachable; gradle falls through on the 404s.
        maven("https://maven.aliyun.com/repository/google")
        maven("https://repo.huaweicloud.com/repository/maven")
        mavenCentral()
    }
}

// Some plugins (geolocator_android 4.x) pin an old AGP in their own
// buildscript classpath (8.0.2) which is not cached and not downloadable on
// this network. Force the same AGP the app uses (declared in settings.gradle.kts)
// so plugin buildscripts resolve against the cached version.
subprojects {
    buildscript {
        configurations.classpath {
            resolutionStrategy {
                force("com.android.tools.build:gradle:9.0.1")
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
