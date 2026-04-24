import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

// ✅ Configure repositories for all projects
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Redefine build directories (moves all subproject build outputs to a common /build folder)
val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()

rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

// ✅ Ensure subprojects depend on :app evaluation
subprojects {
    evaluationDependsOn(":app")
}

// ✅ Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
