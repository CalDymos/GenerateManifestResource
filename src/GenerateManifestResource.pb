; -----------------------------------------------------------------------------
; GenerateManifestResource.pb
; Purpose: Generate a Win32 RT_MANIFEST resource (Resource.rc + Data_1.bin)
;          with PerMonitorV2 DPI awareness for embedding into the final EXE.
;
; Usage:
;   - Optional parameter 0: output directory
;   - If omitted and executed from the PB IDE external tools, PB_TOOL_Project is used.
; -----------------------------------------------------------------------------

EnableExplicit

; ###########################
; Settings
; ###########################
#ENABLE_MODERN_THEME_SUPPORT = #True
#ENABLE_PER_MONITOR_V2       = #True

; Set to empty string to omit trustInfo.
#REQUEST_EXECUTION_LEVEL$    = "asInvoker" ; or "requireAdministrator"

; Repo-relative output folder (used when PB_TOOL_Project is available)
#OUT_REL_DIR$                = "resources\windows\manifest"

; ###########################
; Helpers
; ###########################

Procedure EnsureDirectory(dirPath$)
  Protected normalized$ = ReplaceString(dirPath$, "/", "\")
  If Right(normalized$, 1) = "\"
    normalized$ = Left(normalized$, Len(normalized$) - 1)
  EndIf

  Protected base$ = ""
  If Len(normalized$) >= 3 And Mid(normalized$, 2, 1) = ":" And Mid(normalized$, 3, 1) = "\"
    base$ = Left(normalized$, 3) ; "C:\"
    normalized$ = Mid(normalized$, 4)
  EndIf

  Protected partCount = CountString(normalized$, "\") + 1
  Protected current$ = base$
  Protected i, part$

  For i = 1 To partCount
    part$ = StringField(normalized$, i, "\")
    If part$ = ""
      Continue
    EndIf

    current$ + part$ + "\"
    If FileSize(current$) <> -2
      CreateDirectory(current$)
    EndIf
  Next
EndProcedure

Procedure.s GetOutputDir()
  Protected outDir$ = ""

  If CountProgramParameters() > 0
    outDir$ = ProgramParameter(0)
  EndIf

  If outDir$ = ""
    ; Provided by PB IDE external tools environment.
    ; If not present, fallback to current directory.
    Protected projectFile$ = GetEnvironmentVariable("PB_TOOL_Project")
    If projectFile$ <> ""
      outDir$ = GetPathPart(projectFile$) + #OUT_REL_DIR$
    Else
      outDir$ = GetCurrentDirectory() + #OUT_REL_DIR$
    EndIf
  EndIf

  outDir$ = ReplaceString(outDir$, "/", "\")
  If Right(outDir$, 1) <> "\"
    outDir$ + "\"
  EndIf

  ProcedureReturn outDir$
EndProcedure

Procedure WriteRcFile()
  If CreateFile(0, "resource.rc", #PB_Ascii)
    ; 24 = RT_MANIFEST, 1 = manifest resource ID
    WriteString(0, ~"1 24 \"resources\\\\windows\\\\manifest\\\\manifest.bin\"" + #CRLF$)
    CloseFile(0)
  Else
    Debug "Error: Failed to create resource.rc"
    End
  EndIf
EndProcedure

Procedure WriteManifestBin()
  If Not CreateFile(0, "manifest.bin", #PB_Ascii)
    Debug "Error: Failed to create manifest.bin"
    End
  EndIf

  WriteString(0, ~"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" + #LF$)
  WriteString(0, ~"<assembly xmlns=\"urn:schemas-microsoft-com:asm.v1\" manifestVersion=\"1.0\">" + #LF$)

  If #ENABLE_MODERN_THEME_SUPPORT
    WriteString(0, ~"  <dependency>" + #LF$)
    WriteString(0, ~"    <dependentAssembly>" + #LF$)
    WriteString(0, ~"      <assemblyIdentity" + #LF$)
    WriteString(0, ~"        type=\"win32\"" + #LF$)
    WriteString(0, ~"        name=\"Microsoft.Windows.Common-Controls\"" + #LF$)
    WriteString(0, ~"        version=\"6.0.0.0\"" + #LF$)
    ; Microsoft allows "*" to target all platforms.
    WriteString(0, ~"        processorArchitecture=\"*\"" + #LF$)
    WriteString(0, ~"        publicKeyToken=\"6595b64144ccf1df\"" + #LF$)
    WriteString(0, ~"        language=\"*\" />" + #LF$)
    WriteString(0, ~"    </dependentAssembly>" + #LF$)
    WriteString(0, ~"  </dependency>" + #LF$)
  EndIf

  If #ENABLE_PER_MONITOR_V2
    WriteString(0, ~"  <asmv3:application xmlns:asmv3=\"urn:schemas-microsoft-com:asm.v3\">" + #LF$)
    WriteString(0, ~"    <asmv3:windowsSettings>" + #LF$)

    ; Fallback for older systems (Per-Monitor v1)
    WriteString(0, ~"      <dpiAware xmlns=\"http://schemas.microsoft.com/SMI/2005/WindowsSettings\">true/pm</dpiAware>" + #LF$)

    ; Per-Monitor v2 (Win10+), ordered fallback list
    WriteString(0, ~"      <dpiAwareness xmlns=\"http://schemas.microsoft.com/SMI/2016/WindowsSettings\">PerMonitorV2, PerMonitor</dpiAwareness>" + #LF$)

    WriteString(0, ~"    </asmv3:windowsSettings>" + #LF$)
    WriteString(0, ~"  </asmv3:application>" + #LF$)
  EndIf

  If #REQUEST_EXECUTION_LEVEL$ <> ""
    WriteString(0, ~"  <trustInfo xmlns=\"urn:schemas-microsoft-com:asm.v2\">" + #LF$)
    WriteString(0, ~"    <security>" + #LF$)
    WriteString(0, ~"      <requestedPrivileges>" + #LF$)
    WriteString(0, ~"        <requestedExecutionLevel level=\"" + #REQUEST_EXECUTION_LEVEL$ + ~"\" uiAccess=\"false\" />" + #LF$)
    WriteString(0, ~"      </requestedPrivileges>" + #LF$)
    WriteString(0, ~"    </security>" + #LF$)
    WriteString(0, ~"  </trustInfo>" + #LF$)
  EndIf

  WriteString(0, ~"</assembly>" + #LF$)
  CloseFile(0)
EndProcedure

; ###########################
; Main
; ###########################
Define outDir$ = GetOutputDir()
EnsureDirectory(outDir$)
SetCurrentDirectory(outDir$)

WriteRcFile()
WriteManifestBin()

Debug "Manifest resources generated in: " + outDir$
