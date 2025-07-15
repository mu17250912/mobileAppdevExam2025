// Top-level build file where you can add configuration options common to all sub-projects/modules.

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // ✅ Add Firebase Google Services plugin
        classpath("com.google.gms:google-services:4.3.15")

        // ✅ Make sure Android Gradle Plugin is here too (match your project version)
        classpath("com.android.tools.build:gradle:8.3.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Optional custom build directory logic
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// ✅ Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
