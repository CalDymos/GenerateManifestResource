; -----------------------------------------------------------------------------
; GenerateManifestResource.pb
; Version: 1.1.5
; Purpose: Generate a Win32 RT_MANIFEST resource (resource.rc + manifest.bin)
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
#DEFAULT_DPI_MODE$ = "pmv2" ; pmv2 | system | off

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

Procedure.i IsDpiMode(value$)
  Protected v$ = LCase(Trim(value$))
  ProcedureReturn Bool(v$ = "pmv2" Or v$ = "system" Or v$ = "off")
EndProcedure

Procedure.s GetOutputDir()
  Protected outDir$ = ""
  Protected p0$ = ""

  If CountProgramParameters() > 0
    p0$ = ProgramParameter(0)

    ; If param0 is a known DPI mode, treat it as mode (no outDir override)
    If Not IsDpiMode(p0$)
      outDir$ = p0$
    EndIf
  EndIf

  If outDir$ = ""
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

Procedure.s GetDpiMode()
  Protected mode$ = #DEFAULT_DPI_MODE$

  If CountProgramParameters() >= 2
    mode$ = ProgramParameter(1)
  ElseIf CountProgramParameters() = 1
    If IsDpiMode(ProgramParameter(0))
      mode$ = ProgramParameter(0)
    EndIf
  EndIf

  mode$ = LCase(Trim(mode$))
  If Not IsDpiMode(mode$)
    mode$ = #DEFAULT_DPI_MODE$
  EndIf

  ProcedureReturn mode$
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
  
  Protected dpiMode$ = GetDpiMode()
  
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
  
  If dpiMode$ <> "off"
    WriteString(0, ~"  <asmv3:application xmlns:asmv3=\"urn:schemas-microsoft-com:asm.v3\">" + #LF$)
    WriteString(0, ~"    <asmv3:windowsSettings>" + #LF$)
  
    Select dpiMode$
      Case "pmv2"
        WriteString(0, ~"      <dpiAware xmlns=\"http://schemas.microsoft.com/SMI/2005/WindowsSettings\">true/pm</dpiAware>" + #LF$)
        WriteString(0, ~"      <dpiAwareness xmlns=\"http://schemas.microsoft.com/SMI/2016/WindowsSettings\">PerMonitorV2, PerMonitor</dpiAwareness>" + #LF$)
  
      Case "system"
        ; System DPI awareness
        WriteString(0, ~"      <dpiAware xmlns=\"http://schemas.microsoft.com/SMI/2005/WindowsSettings\">true</dpiAware>" + #LF$)
        ; Optional: You can also emit dpiAwareness=System, but dpiAware=true is widely used.
        ; WriteString(0, ~"      <dpiAwareness xmlns=\"http://schemas.microsoft.com/SMI/2016/WindowsSettings\">System</dpiAwareness>" + #LF$)
    EndSelect
  
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

Procedure.i IsLocalName(node.i, expected$)
  Protected name$ = GetXMLNodeName(node)
  If FindString(name$, ":")
    name$ = StringField(name$, CountString(name$, ":") + 1, ":")
  EndIf
  ProcedureReturn Bool(LCase(name$) = LCase(expected$))
EndProcedure

Procedure.i FindChildByLocalName(parent.i, childName$)
  Protected node.i = ChildXMLNode(parent)
  While node
    If IsLocalName(node, childName$)
      ProcedureReturn node
    EndIf
    node = NextXMLNode(node)
  Wend
  ProcedureReturn 0
EndProcedure

Procedure.i CheckPbpTargetsOptions(pbpPath$)
  Protected xml.i, root.i, sectionTargets.i, targetNode.i, optionsNode.i
  Protected sectionNode.i, sectionName$
  Protected warnNeeded.i = #False

  If LCase(GetExtensionPart(pbpPath$)) <> "pbp"
    ProcedureReturn #False
  EndIf

  If FileSize(pbpPath$) <= 0
    ProcedureReturn #False
  EndIf

  xml = LoadXML(#PB_Any, pbpPath$)
  If xml = 0
    ProcedureReturn #False
  EndIf

  root = MainXMLNode(xml)
  If root = 0
    FreeXML(xml)
    ProcedureReturn #False
  EndIf

  ; Find <section name="targets">
  sectionNode = ChildXMLNode(root)
  While sectionNode
    If IsLocalName(sectionNode, "section")
      sectionName$ = GetXMLAttribute(sectionNode, "name")
      If LCase(sectionName$) = "targets"
        sectionTargets = sectionNode
        Break
      EndIf
    EndIf
    sectionNode = NextXMLNode(sectionNode)
  Wend

  If sectionTargets = 0
    FreeXML(xml)
    ProcedureReturn #False
  EndIf

  ; Check all <target> options
  targetNode = ChildXMLNode(sectionTargets)
  While targetNode
    If IsLocalName(targetNode, "target")
      optionsNode = FindChildByLocalName(targetNode, "options")
      If optionsNode

        If GetXMLAttribute(optionsNode, "xpskin") <> "0"
          warnNeeded = #True
        EndIf

        If GetXMLAttribute(optionsNode, "dpiaware") <> "0"
          warnNeeded = #True
        EndIf

      EndIf
    EndIf
    targetNode = NextXMLNode(targetNode)
  Wend

  FreeXML(xml)

  If warnNeeded
      MessageRequester("Warning",
      "The 'DPIAware' And/Or 'XPSkin' options are enabled in the project." + #CRLF$ +
      "These must be disabled so that the manifest can be integrated correctly.")
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.i CheckProjectFromIdeEnv()
  Protected projectPath$ = GetEnvironmentVariable("PB_TOOL_Project")
  If projectPath$ = ""
    ProcedureReturn #False
  EndIf
  ProcedureReturn CheckPbpTargetsOptions(projectPath$)
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

If Not CheckProjectFromIdeEnv()
  Debug "Check failed or no .pbp project detected."
Else
  Debug "Check OK: xpskin=0, dpiaware=0"
EndIf
