@echo off
REM Title: WebM Enhanced Multithreading Batch Script
REM Author: VP8M8
REM Version: v0.7.2
REM Date: 7/20/2015
REM How to use: Drag a video onto this batch file to start

REM Current Bugs:
REM     * Custom titles cannot have spaces
REM     * Time needs leading zeros for single digit numbers.
REM To Do List in Priority Order:
REM	* Subtitles using the quick search hack
REM	* Show target bitrate vs actual bitrate stats
REM     * Force 854x480 instead of 853x480 for 480p 16:9 videos
REM	* Incorporate trimming into the Forced Multithreading option
REM	* Automatic output resolution scaling based on input resolution and time option
REM	* Auto high/low complexity video bitrate compensation calculation option
REM	* Optimize the Forced Multithreading option for n cores based on user input

REM ***** EDIT THE TWO LINES BELOW TO POINT TO THE LOCATION OF YOUR COPY OF FFMPEG AND FFPROBE *****

set ffmpeg=C:\Users\Anon\Documents\ffmpeg-20150517-git-2acc065-win64-static\bin\ffmpeg.exe
set ffprobe=C:\Users\Anon\Documents\ffmpeg-20150517-git-2acc065-win64-static\bin\ffprobe.exe

REM ********* Test to see if user chose a video **********

if defined "%1" (
    goto :beginning
) else (
    echo Drag and drop a video onto this batch file to start. This window will close.&pause&exit
)

:beginning
REM ********* Hack to get duration ***************

for /f %%x in ('%ffprobe% %1 -loglevel quiet -show_format ^| findstr "="') do set %%x

REM ********* Hack to get date/time ***************

for /f %%x in ('wmic path win32_utctime get /format:list ^| findstr "="') do set %%x
set today=%Year%-%Month%-%Day% 
REM The time %Hour%:%Minute%:%Second%

echo ^| ^|  ^| ^|    ^| ^|   ^|  \/  ^| ^|  ___^|                  ^| ^|         
echo ^| ^|  ^| ^| ___^| ^|__ ^| .  . ^| ^| ^|__ _ __   ___ ___   __^| ^| ___ _ __ 
echo ^| ^|/\^| ^|/ _ \ '_ \^| ^|\/^| ^| ^|  __^| '_ \ / __/ _ \ / _` ^|/ _ \ '__^|
echo \  /\  /  __/ ^|_) ^| ^|  ^| ^| ^| ^|__^| ^| ^| ^| ^(_^| (_) ^| (_^| ^|  __/ ^|   
echo  \/  \/ \___^|_.__/\_^|  ^|_/ \____/_^| ^|_^|\___\___/ \__,_^|\___^|_^|   
echo Make sure you changed the two lines in the script!
echo Press ENTER for the default values
echo.

REM ********** Set title ************

set /p title="What should the title be? Custom titles cannot have spaces.(Default is input file name): "
if [%title%]==[] @set title=%~n1
echo The title is "%title%"

:audiobitrate
REM ********** Audio bitrate *************

if [%bitrateError%]==[1] @echo Error! The video bitrate is negative because the audio bitrate was set too high for the file size. Please set a higher file size or a lower audio bitrate.
set /a bitrateError=0
echo.

set /a length = %duration%

set /p megabytesinput="How big should the WebM be in MB? (Default is 8): "
set /a megabytes=%megabytesinput%
if [%megabytes%]==[] @set /a megabytes=8
echo The file size is %megabytes%MB
echo.

set /p audioenable="Enable audio? Y/N (Default Y): "
set /a audiobitrate=0
if [%audioenable%]==[] @set audioOptions=-ac 2&echo Audio is enabled
if [%audioenable%]==[y] @set audioOptions=-ac 2&echo Audio is enabled
if [%audioenable%]==[Y] @set audioOptions=-ac 2&echo Audio is enabled
if [%audioenable%]==[n] echo Audio is disabled&goto :videoBitrate
if [%audioenable%]==[N] echo Audio is disabled&goto :videoBitrate
echo.

set /p audiobitrateinput="What should the audio bitrate be in kbps? (Default is 64): "
set /a audiobitrate=%audiobitrateinput%
if [%audiobitrate%]==[0] @set audiobitrate=64
echo The audio bitrate is %audiobitrate%kbps

:videoBitrate
REM ********** Video Bitrate *******************

if %audiobitrate% EQU 0 @set audioOptions=-sn
set /a calculatedbitrate=%megabytes% * 8 * 1024 * 1024 / 1000 / %length% - %audiobitrate%

echo The calculated video bitrate is %calculatedbitrate%kbps
echo.

set /p videobitrateinput="What should the video bitrate be in kbps? (Default is auto calculated based on file size. *May be slightly bigger or smaller depending on input video and Quality setting*): "
set /a videobitrate=%videobitrateinput%
if [%videobitrate%]==[] @set /a videobitrate=%calculatedbitrate%
echo The video bitrate is %videobitrate%
echo.

REM # Catches if the auto calculated bitrate is negative.
if %calculatedbitrate% LEQ 0 @set /a bitrateError=1
if %bitrateError% EQU 1 goto :audiobitrate

REM ************** Set Scaling ***********************

set /p scaleheightinput="What should be the height? (Default is input height): "
set /a scaleheight=%scaleheightinput%
if [%scaleheight%]==[] @set /a scaleheight=-1
set scale="scale=-1:%scaleheight%"
echo The scaled height is %scaleheight%
echo.

REM ************** Set Quality ***********************

set codec=libvpx-vp9

echo There are four quality settings. The higher the setting the better it will look but the longer it takes to convert.
echo    Low(1) : VP8 + Optimizations - Multithreaded
echo Medium(2) : VP9 + Tweak - Multithreaded
echo   High(3) : VP9 + Optimizations - Single Threaded
echo  Ultra(4) : VP9 + More Optimizations - Single Threaded
set /p qualityinput="What quality level should the WebM be? (Default is 2): "
set /a quality=%qualityinput%
if [%quality%]==[] @set options=-cpu-used 1 -frame-parallel 0 -threads 4 -pix_fmt yuv420p&@set qualitymode=Medium(2)
if [%quality%]==[1] @set codec=libvpx&@set options= -cpu-used 1 -auto-alt-ref 1 -lag-in-frames 25 -sws_flags lanczos -g 9999 -threads 4 -pix_fmt yuv420p&@set qualitymode=Low(1)
if [%quality%]==[2] @set options=-cpu-used 1 -frame-parallel 0 -threads 4 -pix_fmt yuv420p&@set qualitymode=Medium(2)
if [%quality%]==[3] @set options=-cpu-used 1 -lag-in-frames 25 -auto-alt-ref 1 -frame-parallel 0 -tile-columns 0 -sws_flags lanczos -threads 1 -pix_fmt yuv420p&@set qualitymode=High(3)
if [%quality%]==[4] @set options=-cpu-used 0 -lag-in-frames 25 -auto-alt-ref 1 -frame-parallel 0 -tile-columns 0 -sws_flags lanczos -threads 1 -pix_fmt yuv420p&@set qualitymode=Ultra(4)
echo The quality setting is %qualitymode%
echo.

REM ************** Set Experimental Multithreading **************
echo Forced Multithreading (Experimental):
echo This splits the video into 4 equal parts to encode/combine them to take advantage of at least 4 threads. This generally results in around the same file size with slightly lower quality but is typically over 2x faster on a multicore CPU. Only use with the High(3) or Ultra(4) quality settings. You will be unable to trim your video or enable subtitles if you enable this option. Do not touch the 4 extra windows that pop up.
echo.
set /p experimental="Use Forced Multithreading? Y/N (Default is N): "
if [%experimental%]==[] goto :normalencoding
if [%experimental%]==[n] goto :normalencoding
if [%experimental%]==[N] goto :normalencoding
if [%experimental%]==[y] goto :multithreaded
if [%experimental%]==[Y] goto :multithreaded

:multithreaded
REM [][][][][][][][][][][][][][][][][] MULTITHREADED ENCODING HERE [][][][][][][][][][][][][][][][][][]

REM ~~~~~~~~~~~~~~ Start Script Timer ~~~~~~~~~~~~~

echo.
set starttimescript=%time%

REM Get encoding start time:
for /F "tokens=1-4 delims=:.," %%a in ("%starttimescript%") do (
   set /A "start=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)

REM ************** Set Fourths ***********************

set /a firstFourth = %length% / 4
set /a secondFourth = %firstFourth% * 2
set /a thirdFourth = %secondFourth% + %firstFourth%

REM ************ FIRST FOURTH ******************

(
echo %ffmpeg% -y -i "%~1" -c:v %codec% -b:v %videobitrate%k -vf scale=-1:%scaleheight% -t %firstFourth% %options% -c:a libopus -b:a %audiobitrate%k %audioOptions% -sn -an -f webm -passlogfile ffmpeg2pass-1 -pass 1 NUL
echo %ffmpeg% -y -i "%~1" -c:v %codec% -b:v %videobitrate%k -vf scale=-1:%scaleheight% -t %firstFourth% %options% -c:a libopus -b:a %audiobitrate%k %audioOptions% -sn -an -f webm -passlogfile ffmpeg2pass-1 -pass 2 "webm_part_1.webm"
echo echo. ^> part1done.txt
echo exit
) > part1.bat

start part1.bat

REM ************** SECOND FOURTH *****************

(
echo %ffmpeg% -y -ss %firstFourth% -i "%~1" -c:v %codec% -b:v %videobitrate%k -vf scale=-1:%scaleheight% -t %firstFourth% %options% -c:a libopus -b:a %audiobitrate%k %audioOptions% -sn -an -f webm -passlogfile ffmpeg2pass-2 -pass 1 NUL
echo %ffmpeg% -y -ss %firstFourth% -i "%~1" -c:v %codec% -b:v %videobitrate%k -vf scale=-1:%scaleheight% -t %firstFourth% %options% -c:a libopus -b:a %audiobitrate%k %audioOptions% -sn -an -f webm -passlogfile ffmpeg2pass-2 -pass 2 "webm_part_2.webm"
echo echo. ^> part2done.txt
echo exit
) > part2.bat

start part2.bat 

REM *************** THIRD FOURTH *****************

(
echo %ffmpeg% -y -ss %secondFourth% -i "%~1" -c:v %codec% -b:v %videobitrate%k -vf scale=-1:%scaleheight% -t %firstFourth% %options% -c:a libopus -b:a %audiobitrate%k %audioOptions% -sn -an -f webm -passlogfile ffmpeg2pass-3 -pass 1 NUL
echo %ffmpeg% -y -ss %secondFourth% -i "%~1" -c:v %codec% -b:v %videobitrate%k -vf scale=-1:%scaleheight% -t %firstFourth% %options% -c:a libopus -b:a %audiobitrate%k %audioOptions% -sn -an -f webm -passlogfile ffmpeg2pass-3 -pass 2 "webm_part_3.webm"
echo echo. ^> part3done.txt
echo exit
) > part3.bat

start part3.bat

REM **************** FOURTH FOURTH *******************

(
echo %ffmpeg% -y -ss %thirdFourth% -i "%~1" -c:v %codec% -b:v %videobitrate%k -vf scale=-1:%scaleheight% -to %duration% %options% -c:a libopus -b:a %audiobitrate%k -sn -an -f webm -passlogfile ffmpeg2pass-4 -pass 1 NUL
echo %ffmpeg% -y -ss %thirdFourth% -i "%~1" -c:v %codec% -b:v %videobitrate%k -vf scale=-1:%scaleheight% -to %duration% %options% -c:a libopus -b:a %audiobitrate%k -sn -an -f webm -passlogfile ffmpeg2pass-4 -pass 2 "webm_part_4.webm"
echo echo. ^> part4done.txt
echo exit
) > part4.bat

start part4.bat

REM ****************** CHECK IF PARTS ARE DONE ********************

cls
echo Forced Multithreading is enabled
echo Waiting for the parts to finish...

:reCheck
timeout /t 2 /nobreak > NUL
goto :checkPart1

:checkPart1
if exist "%~dp1part1done.txt" (
	goto :checkPart2
) else (
	goto :reCheck)

:checkPart2
if exist "%~dp1part2done.txt" (
	goto :checkPart3
) else (
	goto :reCheck)

:checkPart3
if exist "%~dp1part3done.txt" (
	goto :checkPart4
) else (
	goto :reCheck)

:checkPart4
if exist "%~dp1part4done.txt" (
	goto :concatFile
) else ( 
	goto :reCheck)

REM ****************** MAKES CONCATINATION FILE ********************

:concatFile
(
echo file '%~dp1webm_part_1.webm'
echo file '%~dp1webm_part_2.webm'
echo file '%~dp1webm_part_3.webm'
echo file '%~dp1webm_part_4.webm'
) > concatlist.txt

REM ****************** COMBINES PARTS ********************

%ffmpeg% -y -i "%~1" -c:a opus -b:a %audiobitrate%k -vn "%~dp1webm_audio.opus"
%ffmpeg% -y -f concat -i concatlist.txt -i "%~dp1webm_audio.opus" -map 0:0 -map 1:0 -c copy -metadata creation_time="%today%" -metadata title="%title%" -f webm "%title%.webm"

cls
echo FINISHED ENCODING!!!

DEL /Q /F "%~dp1ffmpeg2pass-1-0.log"
DEL /Q /F "%~dp1ffmpeg2pass-2-0.log"
DEL /Q /F "%~dp1ffmpeg2pass-3-0.log"
DEL /Q /F "%~dp1ffmpeg2pass-4-0.log"
DEL /Q /F "%~dp1part1done.txt"
DEL /Q /F "%~dp1part2done.txt"
DEL /Q /F "%~dp1part3done.txt"
DEL /Q /F "%~dp1part4done.txt"
DEL /Q /F "%~dp1part1.bat"
DEL /Q /F "%~dp1part2.bat"
DEL /Q /F "%~dp1part3.bat"
DEL /Q /F "%~dp1part4.bat"
DEL /Q /F "%~dp1concatlist.txt"
DEL /Q /F "%~dp1webm_audio.opus"
DEL /Q /F "%~dp1webm_part_1.webm"
DEL /Q /F "%~dp1webm_part_2.webm"
DEL /Q /F "%~dp1webm_part_3.webm"
DEL /Q /F "%~dp1webm_part_4.webm"

echo Done cleaning up!

set endtimescript=%time%

REM Get encoding end time:
for /F "tokens=1-4 delims=:.," %%a in ("%endtimescript%") do (
   set /A "end=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)

REM ~~~~~~~~~~~~~~ End Script Timer ~~~~~~~~~~~~~

goto :END

:normalencoding
REM [][][][][][][][][][][][][][][][][] NORMAL ENCODING HERE [][][][][][][][][][][][][][][][][][]

echo Experimental Multithreading is dissabled
echo.

REM ************** Set Subtitles *******************

set /p insubs="Include Subtitles? Y/N (Default N): "
set subsback=%1
set subsback=%subsback:\=\\%
set subsback=%subsback:'='\\\''%
set subsback=%subsback::=\:%
set subsback=%subsback:[=\[%
set subsback=%subsback:]=\]%
set subsback=%subsback:;=\;%
set subsback=%subsback:,=\,%

REM if [%insubs%]==[y] @set subs=setpts=PTS+%starttime%/TB,subtitles=""'%subsback%'"",setpts=PTS-STARTPTS&@set /a subsinclude=1
REM if [%insubs%]==[Y] @set subs=setpts=PTS+%starttime%/TB,subtitles=""'%subsback%'"",setpts=PTS-STARTPTS&@set /a subsinclude=1
if [%insubs%]==[y] @set subs=subtitles=""'%subsback%'""&@set /a subsinclude=1
if [%insubs%]==[Y] @set subs=subtitles=""'%subsback%'""&@set /a subsinclude=1
if [%insubs%]==[n] @set /a subsinclude=0
if [%insubs%]==[N] @set /a subsinclude=0
if [%insubs%]==[] @set /a subsinclude=0&@set insubs=N
echo Subtitles enabled: %insubs%
echo.

if %subsinclude% EQU 1 (@set filter=%scale%,%subs%)
if %subsinclude% EQU 0 (@set filter=%scale%)

REM ************** Set video trim *********************

set starttime=00:00:00.00
set endtime=%duration%
REM set starttimesubs=

set /p trim="Do you need to trim the video? Y/N (Default N): "
if [%trim%]==[] goto :normal
if [%trim%]==[n] goto :normal
if [%trim%]==[N] goto :normal
if [%trim%]==[y] goto :trim
if [%trim%]==[Y] goto :trim

:trim
set /p starttime="What should the start time be in HH:MM:SS.CC format? Ex: 00:01:48.00 (Default is 00:00:00.00): "
if [%starttime%]==[] @set starttime=00:00:00.00
echo The start time is %starttime%
echo.

REM if %subsinclude% EQU 1 (@set starttimesubs=%starttime%&@set starttime=)

set /p endtime="What should the end time be in HH:MM:SS.CC format? Ex: 00:08:56.20 (Default is total length of input video): "
if [%endtime%]==[] @set endtime=%duration%
echo The end time is %endtime%

:normal 

REM ~~~~~~~~~~~~~~~~~~ Start Script Timer ~~~~~~~~~~~~~~~~~~~

set starttimescript=%time%

REM Get encoding start time:
for /F "tokens=1-4 delims=:.," %%a in ("%starttimescript%") do (
   set /A "start=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)

%ffmpeg% -y -i "%~1" -ss %starttime% -to %endtime% -c:v %codec% -b:v %videobitrate%k -vf %filter% -sn %options% -c:a libopus -b:a %audiobitrate%k %audioOptions% -f webm -an -pass 1 NUL
%ffmpeg% -y -i "%~1" -ss %starttime% -to %endtime% -c:v %codec% -b:v %videobitrate%k -vf %filter% -sn %options% -c:a libopus -b:a %audiobitrate%k %audioOptions% -f webm -metadata title="%title%" -metadata creation_time=%today% -pass 2 "%title%.webm"

cls
echo FINISHED ENCODING!!!
DEL /Q /F "%~dp1ffmpeg2pass-0.log"
echo Done cleaning up!

set endtimescript=%time%

REM Get encoding end time:
for /F "tokens=1-4 delims=:.," %%a in ("%endtimescript%") do (
   set /A "end=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)

REM ~~~~~~~~~~~~~~ End Script Timer ~~~~~~~~~~~~~

:END

REM Get elapsed encoding time:
set /A elapsed=%end%-%start%

REM Show elapsed time:
set /A hh=elapsed/(60*60*100), rest=elapsed%%(60*60*100), mm=rest/(60*100), rest%%=60*100, ss=rest/100, cc=rest%%100
if %mm% lss 10 set mm=0%mm%
if %ss% lss 10 set ss=0%ss%
if %cc% lss 10 set cc=0%cc%

echo.
echo Conversion stats:
echo Target audio bitrate: %audiobitrate%k
echo Target video bitrate: %videobitrate%k
set /a targetbitrate=%audiobitrate% + %videobitrate%
echo Target total bitrate: %targetbitrate%k
echo Target file size: %megabytes%MB
echo.
echo Start time: %starttimescript%
echo End time  : %endtimescript%
echo Elasped encoding time is %hh%:%mm%:%ss%.%cc%
pause