@ECHO OFF

SETLOCAL

CALL %CTKBLDROOT%setupEnv.cmd

SET BASENAME=Cyotek.Windows.Forms.ColorPicker
SET RELDIR=%BASENAME%\bin\Release\
SET PRJFILE=%BASENAME%\%BASENAME%.csproj
SET DLLNAME=%BASENAME%.dll

SET DEMOPRJFILE=%BASENAME%.Demo\%BASENAME%.Demo.csproj
SET DEMORELDIR=%BASENAME%.Demo\bin\Release\net48\
SET DEPDIR=demo\

SET DISTDIR=dist\

IF EXIST %RELDIR%*.nupkg  DEL /F %RELDIR%*.nupkg
IF EXIST %RELDIR%*.snupkg DEL /F %RELDIR%*.snupkg
IF EXIST %RELDIR%*.zip    DEL /F %RELDIR%*.zip
IF EXIST %DEPDIR%         RMDIR /Q /S %DEPDIR%
IF EXIST %DISTDIR%        RMDIR /Q /S %DISTDIR%

MKDIR %DISTDIR%

CALL :builddemo
IF %ERRORLEVEL% NEQ 0 GOTO :failed

CALL :buildpackage
IF %ERRORLEVEL% NEQ 0 GOTO :failed

ENDLOCAL

GOTO :eof

:buildfailed
:failed
cecho {0c}ERROR  {#}: Build failed.{\n}
exit /b 1

:builddemo
%msbuildexe% %DEMOPRJFILE% /p:Configuration=Release /verbosity:minimal /nologo /t:Clean,Build
IF %ERRORLEVEL% NEQ 0 GOTO :failed

MKDIR %DEPDIR%
MKDIR %DEPDIR%\bin
MKDIR %DEPDIR%\palettes
MKDIR %DEPDIR%\docs

COPY %DEMORELDIR%demo.exe                               %DEPDIR%
COPY %DEMORELDIR%demo.pdb                               %DEPDIR%
COPY %DEMORELDIR%demo.exe.config                        %DEPDIR%
COPY %DEMORELDIR%CommonMark.dll                         %DEPDIR%bin
COPY %DEMORELDIR%Cyotek.Windows.Forms.ColorPicker.dll   %DEPDIR%bin
COPY %DEMORELDIR%Cyotek.Windows.Forms.ColorPicker.pdb   %DEPDIR%bin
COPY %DEMORELDIR%HtmlRenderer.dll                       %DEPDIR%bin
COPY %DEMORELDIR%HtmlRenderer.WinForms.dll              %DEPDIR%bin
COPY %DEMORELDIR%palettes\*.*                           %DEPDIR%palettes
COPY %DEMORELDIR%docs\*.*                               %DEPDIR%docs

PUSHD %DEPDIR%

CALL signcmd demo.exe
CALL signcmd bin\Cyotek.Windows.Forms.ColorPicker.dll

%zipexe% a %BASENAME%.Demo.2.x.x.zip -r

POPD

COPY %DEPDIR%*.zip %DISTDIR%

exit /b %ERRORLEVEL%

:buildpackage
dotnet build %PRJFILE% --configuration Release
IF %ERRORLEVEL% NEQ 0 GOTO :failed

PUSHD %RELDIR%

CALL signcmd net35\%DLLNAME%
CALL signcmd net40\%DLLNAME%
CALL signcmd net452\%DLLNAME%
CALL signcmd net462\%DLLNAME%
CALL signcmd net472\%DLLNAME%
CALL signcmd net48\%DLLNAME%
CALL signcmd netcoreapp3.1\%DLLNAME%
CALL signcmd net5.0-windows\%DLLNAME%

%zipexe% a %BASENAME%.2.x.x.zip -r

POPD

COPY %RELDIR%*.zip %DISTDIR%

dotnet pack %PRJFILE% --configuration Release --no-build
IF %ERRORLEVEL% NEQ 0 GOTO :failed

CALL sign-package %RELDIR%*.nupkg
CALL sign-package %RELDIR%*.snupkg
exit /b %ERRORLEVEL%
