# Don't allow our script to continue if any errors are observed
$ErrorActionPreference = "Stop"

# We will assume that we'll use Java that is bundled with Android Studio.
# $env:JAVA_HOME="D:\Program Files\Android\Android Studio\jbr"
# we use this command to set env var permanently
[System.Environment]::SetEnvironmentVariable('JAVA_HOME', 'C:\Program Files\Android\Android Studio\jbr',[System.EnvironmentVariableTarget]::Machine)

# We will assume that the Android SDK is in the default location that Android Studio installs it to.
# $env:ANDROID_HOME="C:\Users\$env:UserName\AppData\Local\Android\Sdk"
# we use this command to set env var permanently
$userName = $env:UserName
$androidHome = 'C:\Users\' + $userName + '\AppData\Local\Android\Sdk'
[System.Environment]::SetEnvironmentVariable('ANDROID_HOME', $androidHome,[System.EnvironmentVariableTarget]::Machine)

# We get env var ANDROID_HOME from the system
$androidHome = [System.Environment]::GetEnvironmentVariable('ANDROID_HOME','machine')
Write-Host "Using Android SDK at:" $androidHome

# We will be using a specific version of the Android NDK.
$ndkVersion="20.0.5594570"
#$env:ANDROID_NDK="$env:ANDROID_HOME\ndk\$NDK_VERSION"
$androidNdk = $androidHome + '\ndk\' + $ndkVersion
[System.Environment]::SetEnvironmentVariable('ANDROID_NDK', $androidNdk ,[System.EnvironmentVariableTarget]::Machine)

Write-Host "Using Android NDK at:" $androidNdk

# this sdkManager was downloaded separatly as zip and placed at sdk root: C:\Users\user\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\ 
# because default sdkManager that was shipped with AndroidStudio and located at C:\Users\user\AppData\Local\Android\Sdk\tools\bin 
# does not work
$sdkManagerLocation = "C:\Users\" + $userName + "\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\"

Push-Location -Path $sdkManagerLocation
    Write-Host "Reviewing Android SDK licenses ..."

# Create a file that can answer 'y' to each of the Android licenses automatically.
Set-Content -Path 'yes.txt' -Value "y`r`ny`r`ny`r`ny`r`ny`r`ny`r`ny`r`ny`r`ny`r`ny`r`n"
cmd.exe /c 'sdkmanager.bat --licenses < yes.txt'
Remove-Item -Path 'yes.txt'

Write-Host "Installing required Android SDK components ..."
cmd.exe /c "sdkmanager.bat platform-tools build-tools;28.0.3 tools platforms;android-28 cmake;3.10.2.4988404 ndk;$ndkVersion"
Pop-Location

# Check that we have a 'third-party' folder
Push-Location -Path "..\..\"
if (!(Test-Path "third-party")) {
    New-Item -ItemType Directory -Path "third-party"
}
Pop-Location

# Check that we have the SDL third party source folder.
$destDirRelative = Resolve-Path "..\..\third-party\"
$destDirAbsolute = Convert-Path $destDirRelative
$destDirAbsoluteWithFilename = $destDirAbsolute + "SDL2-2.0.9.zip"
if (!(Test-Path "..\..\third-party\SDL")) {
    Write-Host "Downloading SDL source into third party folder SDL ..."
    $WebClient = New-Object System.Net.WebClient
    
    $WebClient.DownloadFile("https://www.libsdl.org/release/SDL2-2.0.9.zip", $destDirAbsoluteWithFilename)

    Push-Location -Path "..\..\third-party"
        Write-Host "Unzipping SDL source into third-party\SDL ..."
        cmd.exe /c 'tar -xf SDL2-2.0.9.zip'
        Move-Item -Path SDL2-2.0.9 -Destination SDL
        Remove-Item -Path SDL2-2.0.9.zip
    Pop-Location
}

# If required, create the SDL symlink into the Android library project so it can include it in its build.
if (!(Test-Path "sdl\jni")) {
    New-Item "sdl\jni" -itemType Directory
}

Push-Location "sdl\jni"

if (!(Test-Path "SDL")) {
    Write-Host "Linking third-party\SDL to sdl\jni\SDL."
    cmd.exe /c 'mklink /d SDL ..\..\..\..\third-party\SDL'
}
Pop-Location

# Copy the Java classes from the SDL library source into the Android library project.
Push-Location "sdl\src\main"
if (!(Test-Path "java\org\libsdl")) {
    Write-Host "Copying base SDL Java source to Android library project ..."
    Copy-Item -Path ..\..\..\..\..\third-party\SDL\android-project\app\src\main\java -Recurse -Destination java
}
Pop-Location

Write-Host "All done - import the project in this folder into Android Studio to run it!"