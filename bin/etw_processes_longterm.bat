@rem Copyright 2015 Google Inc. All Rights Reserved.
@rem
@rem Licensed under the Apache License, Version 2.0 (the "License");
@rem you may not use this file except in compliance with the License.
@rem You may obtain a copy of the License at
@rem
@rem     http://www.apache.org/licenses/LICENSE-2.0
@rem
@rem Unless required by applicable law or agreed to in writing, software
@rem distributed under the License is distributed on an "AS IS" BASIS,
@rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@rem See the License for the specific language governing permissions and
@rem limitations under the License.

@setlocal

@set logger="Circular Kernel Context Logger"
@rem Can also use "NT Kernel Logger", but that conflicts with UIforETW
@rem Better to use a different kernel logger to let them run in parallel.

@rem Set the etwtracedir environment variable if it
@rem isn't set already.
@if not "%etwtracedir%" == "" goto TraceDirSet
@set etwtracedir=%homedrive%%homepath%\documents\etwtraces
:TraceDirSet

@rem Make sure %etwtracedir% exists
@if exist "%etwtracedir%" goto TraceDirExists
@mkdir "%etwtracedir%"
:TraceDirExists

@rem Generate a file name based on the current date and time and put it in
@rem etwtracedir. This is compatible with UIforETW which looks for traces there.
@for /f "delims=" %%A in ('powershell get-date -format "{yyyy-MM-dd_HH-mm-ss}"') do @set datetime=%%A
@set tracefile=%etwtracedir%\%datetime%_process_creation.etl
@set textfile=%etwtracedir%\%datetime%_process_creation.txt

@set kernelfile=%temp%\kernel_trace.etl

@xperf.exe -start %logger% -on PROC_THREAD+LOADER -buffersize 1024 -minbuffers 60 -maxbuffers 60 -f "%kernelfile%"
@set starttime=%time%
@if not %errorlevel% equ 0 goto failure
@echo Low data-rate tracing started at %starttime%

@echo Run the test you want to profile here
@rem Can replace "pause" with "timeout 3600" so that tracing automatically stops
@rem after an hour. But this will require some process to wake up once a second
@rem to update the timeout status.
@pause
@xperf.exe -stop %logger%
@xperf.exe -merge "%kernelfile%" "%tracefile%" -compress
@del "%kernelfile%"
@echo Tracing ran from %starttime% to %time%
@echo Tracing ran from %starttime% to %time% > "%textfile%"

@echo Trace can be loaded using UIforETW or with:
@echo wpa "%tracefile%" -profile TransientProcessTree.wpaProfile
@exit /b

:failure
@echo Failure! Stopping tracing to clear state.
@xperf.exe -stop %logger%
@exit /b
