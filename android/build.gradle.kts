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

subprojects {
    val configureCompileSdk = {
        val androidExt = project.extensions.findByName("android")
        if (androidExt != null) {
            var updated = false
            for (method in androidExt.javaClass.methods) {
                if (method.name == "setCompileSdk" && method.parameterTypes.size == 1) {
                    try {
                        method.invoke(androidExt, 36)
                        updated = true
                        break
                    } catch (_: Exception) {}
                }
            }
            if (!updated) {
                for (method in androidExt.javaClass.methods) {
                    if (method.name == "compileSdkVersion" && method.parameterTypes.size == 1) {
                        try {
                            if (method.parameterTypes[0] == Int::class.javaPrimitiveType) {
                                method.invoke(androidExt, 36)
                                break
                            } else if (method.parameterTypes[0] == String::class.java) {
                                method.invoke(androidExt, "android-36")
                                break
                            }
                        } catch (_: Exception) {}
                    }
                }
            }
        }
    }

    if (project.state.executed) {
        configureCompileSdk()
    } else {
        project.afterEvaluate { configureCompileSdk() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

