
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        "classpath"("com.android.tools.build:gradle:8.1.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
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
    plugins.configureEach {
        if (this is com.android.build.gradle.BasePlugin) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            try {
                // Use reflection to set namespace if it exists and is null
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                if (getNamespace.invoke(android) == null) {
                    setNamespace.invoke(android, "dev.isar.${project.name.replace("-", "_")}")
                }
            } catch (e: Exception) {
                // Ignore if method not found (older AGP)
            }
        }
    }
}

// Clean Gradle file; removed dash_bubble namespace injections and manifest hacks

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
