## Micronaut Pi4J Minimal Example

The Micronaut Pi4J Minimal Example project is a simple Micronaut application running the Pi4J V2 code from the [pi4j-example-minimal](https://github.com/Pi4J/pi4j-example-minimal) project.  The goal of this project is to build and run the application as a GraalVM native image on a Raspberry Pi.

## Project Requirements

The GraalVM JDK and native-image build tool for ARM requires a 64-bit processor and a 64-bit operating system.

This project has been tested on [Ubuntu Server 20.04 LTS 64-bit](https://ubuntu.com/download/raspberry-pi).

This project has not been tested on [raspios_arm64](http://downloads.raspberrypi.org/raspios_arm64/), but the project should work on `raspios_arm64`.

[sdkman](https://sdkman.io/) can be used to install the GraalVM JDK.  GraalVM JDK is used to install `native-image` build tool.
1. `sdk list java`
2. `sdk install java 21.3.0.r11-grl`
3. `java -version`
```asciidoc
openjdk version "11.0.13" 2021-10-19
OpenJDK Runtime Environment GraalVM CE 21.3.0 (build 11.0.13+7-jvmci-21.3-b05)
OpenJDK 64-Bit Server VM GraalVM CE 21.3.0 (build 11.0.13+7-jvmci-21.3-b05, mixed mode)
```
4. `gu install native-image`

## Electronics Setup

See [pi4j-example-minimal](https://github.com/Pi4J/pi4j-example-minimal) for setting up the electronics for this project.

## Native Image Build Setup

### Download and Install PIGPIO Library

On target Raspberry Pi

1. Download Package Information From All Configured Sources
   1. `sudo apt update`
2. Install Build Essential (C/C++ compilers, make)
   1. `sudo apt install build-essentials`
3. Install libz-dev
   1. `sudo apt install libz-dev`
4. [Download and Install pigpio library](http://abyz.me.uk/rpi/pigpio/download.html)
   1. **NOTE:** Python is not required.

### Generate GraalVM Native Image Configuration Files

The steps in this section were performed and the generated configuration files are committed to the project repository.  These steps are included for informational purposes to document the complete build process.

1. Clone project on Raspberry Pi
2. cd project directory
3. ./gradlew run
   1. The `jvmArgs` for the `run` build task in [build.gradle](./build.gradle) configures the GraalVM tracing agent to generate the `native-image` configuration files in the `./tmp` directory.
      1. jni-config.json
      2. predefined-classes-config.json
      3. proxy-config.json
      4. reflect-config.json
      5. resource-config.json
      6. serialization-config.json
4. Exercise the application to completion by pressing the switch several times until the LED stops blinking.
5. Copy the required configuration files to the native-image configuration directory `./src/main/resources/META-INF/native-image/com.pi4j/pi4j-core`.  This directory follows the Micronaut convention for the native-image configuration directory `./src/main/resources/META-INF/native-image/<groupId>/<artifactId>/<app>`.  By using this convention, the Micronaut Gradle plugin with automatically use these configuration files in the native image build.
   1. `cp ./tmp/jni-config.json ./src/main/resources/META-INF/native-image/com.pi4j/pi4j-core`
   2. `cp ./tmp/proxy-config.json ./src/main/resources/META-INF/native-image/com.pi4j/pi4j-core`

## Native Image Build

The native image build requires approximately 8 GB of RAM to execute.  An attempt to execute the native image build on a Raspberry Pi 4B with 4GB RAM resulted in the build exiting with an error code of `137` `Out of Memory`.

[Oracle Cloud Infrastructure](https://www.oracle.com/cloud) offers an [ARM](https://www.oracle.com/cloud/compute/arm/) compute instance.  The [Oracle Cloud Free Tier](https://www.oracle.com/cloud/free/) offers an Ampere A1 Compute instance with up to 4 cores and up to 24 GB RAM for free.  The native image successfully built with 3 cores and 16 GB ram in a little over 3 minutes.  

**NOTE:** If an Oracle Cloud compute instance is used to build the native image, `GraalVM JDK` and the `native-image` tool must be installed on the compute instance. See [Project Requirements](#project-requirements)

1. [native-image.properties](./src/main/resources/META-INF/native-image/com.pi4j/pi4j-core/native-image.properties) contains the required `native-image` command line arguments.  This property file is automatically used in the native-image build because the file is located in the directory following the Micronaut convention.
   1. The `com.pi4j.library.pigpio.internal.PIGPIO` class statically loads the JNI library `libpi4j-pigpio.so`.  `native-image` must be configured to statically load the `PIGPIO` class at runtime instead of at build time.
      1. `--initialize-at-run-time=com.pi4j.library.pigpio.internal.PIGPIO` 
2. The `nativeImage` build task in [build.gradle](./build.gradle) is configured to pass the optional `--verbose` command line argument to `native-image`.  Using verbose output helps when trying to understand build or runtime errors.
3. `./gradlew nativeImage` builds the native image.
4. `./build/native-image` contains the native image build artifacts.
   1. `application`
   2. `application.build_artifacts.txt`

## Native Image Execution

1. If the `native-image` `application` is built on a host and not the runtime machine, secure copy the `application` file to target machine.
   1. `scp ./build/native-image/application` `<user>@<target ip>:~`
2. From the user's home directory on the Raspberry Pi target.  The `application` must be executed with `sudo` privileges because the underlying [pigpio](http://abyz.me.uk/rpi/pigpio/) library opens a file descriptor for `/dev/mem`.  The `pi4j.library.path` java system property must be defined when running the native image, so the `application` knows where to find the JNI library.  For simplicity, `libpi4j-pigpio.so` was extracted out of `pi4j-library-pigpio-2.0.jar` and committed to this project's repository in the `./lib` directory.
   1. `sudo ./application -Dpi4j.library.path=<path to this project on Raspberry Pi>/lib/libpi4j-pigpio.so`