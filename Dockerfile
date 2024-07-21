####################################
#       Base image
####################################
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2022


####################################
#       Env variables
####################################
ENV GIT_USER=
ENV GIT_TOKEN=
ENV PROJECT_NAME=


####################################
#       Create setup directory
####################################
COPY Setup C:\\Setup


####################################
#       Use Windows cmd shell
####################################
SHELL ["cmd", "/S", "/C"]


####################################
#       Setup Chocolatey 
####################################
RUN powershell.exe -command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"


####################################
#       Setup cmd line text editors
####################################
RUN choco install nano -y
RUN choco install vim -y
RUN choco install micro -y


####################################
#       Setup Visual Studio
####################################
RUN choco install -y vcredist-all
RUN curl -SL --output C:\vs_community.exe https://aka.ms/vs/16/release/vs_community.exe && start /w C:\vs_community.exe --quiet --wait --norestart --nocache --config "C:\Setup\2019.vsconfig"


####################################
#       Setup Python
####################################
RUN choco install python37 -y
RUN python -m pip install dll-diagnostics


####################################
#       Add required DLL's
####################################
RUN robocopy C:\Setup\GatheredDlls C:\Windows\System32 /E /XC /XN /XO || echo 0


####################################
#       Setup paging file
####################################
RUN wmic computersystem where name="%COMPUTERNAME%" set AutomaticManagedPagefile=False
RUN wmic pagefileset where name="C:\\pagefile.sys" set InitialSize=102400,MaximumSize=102400


####################################
#       Setup graphics API
####################################
RUN echo powershell -ExecutionPolicy Bypass -file "C:\Setup\enable-graphics-apis.ps1" >> c:\startup.bat


####################################
#       Setup Unreal 
####################################
RUN choco install git -y
RUN echo git clone --branch 5.1 --depth=1 https://%GIT_USER%:%GIT_TOKEN%@github.com/EpicGames/UnrealEngine.git C:\UnrealEngine >> c:\startup.bat
RUN echo call C:\UnrealEngine\Setup.bat >> c:\startup.bat
RUN echo robocopy /e C:\Setup\%PROJECT_NAME% C:\UnrealEngine\%PROJECT_NAME% >> c:\startup.bat
RUN echo call C:\UnrealEngine\GenerateProjectFiles.bat >> c:\startup.bat


####################################
#       Setup Android Studio
####################################
RUN curl -SL --output C:\Setup\android-studio-2021.3.1.7-windows.exe "https://redirector.gvt1.com/edgedl/android/studio/install/2021.3.1.7/android-studio-2021.3.1.7-windows.exe" && start /w C:\Setup\android-studio-2021.3.1.7-windows.exe /S
RUN call C:\UnrealEngine\Engine\Extras\Android\SetupAndroid.bat
ENV ANDROID_HOME="C:\Users\ContainerAdministrator\AppData\Local\Android\Sdk"
ENV JAVA_HOME="C:\Program Files\Android\Android Studio\jre"
ENV NDK_ROOT="C:\Users\ContainerAdministrator\AppData\Local\Android\Sdk\ndk\21.4.7075529"
ENV NDKROOT="C:\Users\ContainerAdministrator\AppData\Local\Android\Sdk\ndk\21.4.7075529"


####################################
#       Build Unreal 
####################################
RUN echo C:\UnrealEngine\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe %PROJECT_NAME%Editor Win64 Development >> c:\startup.bat
RUN echo C:\UnrealEngine\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe ShaderCompileWorker Win64 Development >> c:\startup.bat
RUN echo call C:\UnrealEngine\Engine\Build\BatchFiles\RunUAT.bat BuildCookRun -nop4 -project=%PROJECT_NAME% -targetplatform=Android -clientconfig=Development -build -compile -cook -stage -archive -package -pak -compressed -iostore -prereqs -manifests -allmaps -unattended -buildmachine -cookFlavor=ASTC -archivedirectory=C:/Builds/ >> c:\startup.bat


####################################
#       Run the app
####################################
RUN echo ping -t localhost ^>^> C:\pulse.txt  >> C:\Setup\startup.bat
CMD ["c:\\startup.bat"]