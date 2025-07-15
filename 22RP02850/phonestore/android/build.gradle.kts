import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // Required for Android builds
        classpath("com.android.tools.build:gradle:7.4.1")
        // Required for Firebase / Google services
        classpath("com.google.gms:google-services:4.4.2")
        // Required for Kotlin support
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Optional: customize build folder location
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

// Ensure dependencies of subprojects are loaded correctly
subprojects {
    project.evaluationDependsOn(":app")
}

// Clean task to delete build directory
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
