@echo off
:: -----------------------------------------------------------------
:: --- Set the container name
:: -----------------------------------------------------------------
set NAME=ue-containerized-builder


:: -----------------------------------------------------------------
:: --- Remove pre-existing instance of container if found via docker ps
:: -----------------------------------------------------------------
echo Checking for pre-existing instance of %NAME%
docker ps | find /i %NAME%
if not errorlevel 1 (
    echo Found pre-existing instance of %NAME% with command docker ps && echo Cleaning previous instance of %NAME% with command docker container && docker stop %NAME% && docker rm %NAME%
) else (
    echo Previous instance of %NAME% not running with command docker ps)


:: -----------------------------------------------------------------
:: --- Remove pre-existing instance of container if found via docker container
:: -----------------------------------------------------------------
docker container ls --all | find /i %NAME%
if not errorlevel 1 (
    echo Found pre-existing instance of %NAME% with command docker container && echo Cleaning previous instance of %NAME% with command docker container && docker container rm %NAME% 
) else (
    echo Previous instance of %NAME% not running with command docker container)


:: -----------------------------------------------------------------
:: --- Check again if the container successfully exited
:: -----------------------------------------------------------------
FOR /F "tokens=* USEBACKQ" %%F IN (`docker ps --filter name^=^^%NAME%$ -q`) DO (
set "result=%%F")
IF "%result%" == "" echo Container %NAME% is not running


:: -----------------------------------------------------------------
:: --- Build the Docker image file using the latest source files
:: -----------------------------------------------------------------
echo Building %NAME%
docker build -t %NAME% -f nginx.Dockerfile .
if %ERRORLEVEL% NEQ 0 echo Error building Dockerfile 1>&2 && @pause


:: -----------------------------------------------------------------
:: --- Run the container
:: -----------------------------------------------------------------
echo Running new instance of %NAME%
docker run -d --dns "8.8.8.8" --isolation process --device class/5B45201D-F2F2-4F3B-85BB-30FF1F953599 -m 100G --rm --cpu-count 16 --storage-opt size=768G --hostname %NAME% --name %NAME% "%NAME%" 
if %ERRORLEVEL% NEQ 0 echo Error running new instance of %NAME% 1>&2 && @pause


:: -----------------------------------------------------------------
:: --- Make sure the container is actually running
:: -----------------------------------------------------------------
echo Waiting 10 seconds for container to initalize
timeout /t 10

FOR /F "tokens=* USEBACKQ" %%F IN (`docker ps --filter name^=^^%NAME%$ -q`) DO (
set "result=%%F")
IF "%result%" == "" echo Container appears to have stopped running, possible error during initialization 1>&2 && @pause
IF NOT "%result%" == "" echo Container appears to be still running after initialization
:end


:: -----------------------------------------------------------------
:: --- Save logs to local file
:: -----------------------------------------------------------------
echo Capturing container logs to file
mkdir "%CWD%\Logs"
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
For /f "tokens=1-2 delims=/:" %%a in ("%TIME%") do (set mytime=%%a-%%b)
docker logs -f "%NAME%" > "%CWD%\Logs\%NAME%_%mydate%_%mytime%.log" 2>&1


:: -----------------------------------------------------------------
:: --- Keep window open for review
:: -----------------------------------------------------------------
@pause
