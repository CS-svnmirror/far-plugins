{$I Defines.inc} { ��. ����� DefApp.inc }

{$APPTYPE CONSOLE}
{$ImageBase $40A00000}

library FarDebug;

{******************************************************************************}
{* (c) 2009 Max Rusov                                                         *}
{*                                                                            *}
{* GDB Shell for FAR                                                          *}
{******************************************************************************}

uses
  MixErrors,
 {$ifdef bTrace}
  MixCheck,
 {$endif bTrace}
  FarDebugMain;

exports
 {$ifdef bUnicodeFar}
  SetStartupInfoW,
  GetMinFarVersionW,
  GetPluginInfoW,
  OpenPluginW,
  ProcessEditorEventW,
  ExitFARW;
 {$else}
  SetStartupInfo,
  GetPluginInfo,
  OpenPlugin,
  ProcessEditorEvent,
  ExitFAR;
 {$endif bUnicodeFar}

{$ifdef bUnicodeFar}
 {$R FarDebugW.res}
{$else}
 {$R FarDebugA.res}
{$endif bUnicodeFar}

end.
