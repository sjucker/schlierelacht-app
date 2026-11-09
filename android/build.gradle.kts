allprojects {
    repositories {
        google()
        mavenCentral()
        // Mapbox SDK is served from an authenticated Maven repo. The secret
        // downloads token (`sk.*`) is read from gradle.properties /
        // ORG_GRADLE_PROJECT_MAPBOX_DOWNLOADS_TOKEN — see android/gradle.properties.
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            authentication { create<BasicAuthentication>("basic") }
            credentials {
                username = "mapbox"
                password = providers.gradleProperty("MAPBOX_DOWNLOADS_TOKEN").orNull ?: ""
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

// mapbox_maps_flutter_mobile 3.x only applies `kotlin-android` on AGP < 9,
// assuming AGP 9's built-in Kotlin otherwise. This project runs AGP 9 with
// `android.builtInKotlin=false` (gradle.properties), so neither applies and its
// `kotlin { compilerOptions { ... } }` block fails. Apply the plugin for it.
subprojects {
    if (name == "mapbox_maps_flutter_mobile") {
        plugins.withId("com.android.library") {
            apply(plugin = "org.jetbrains.kotlin.android")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
