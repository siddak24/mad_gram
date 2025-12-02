import com.android.build.api.dsl.TestedExtension
import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.file.Directory

// 🌟 START OF CRITICAL FIX: The buildscript block 🌟
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Use the stable, recent Android Gradle Plugin version
        classpath("com.android.tools.build:gradle:8.0.0") 
        
        // Use a recent, stable Kotlin version
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.0")
    }
}
// 🌟 END OF CRITICAL FIX 🌟


// ----------------------------------------------------
// YOUR EXISTING CODE FOLLOWS:
// ----------------------------------------------------
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
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
```



    
