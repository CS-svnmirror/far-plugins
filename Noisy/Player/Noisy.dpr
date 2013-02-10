{$I Defines.inc} { ��. ����� DefApp.inc }

{$ImageBase $01000000}

program Noisy;

{$I Defines1.inc}

uses
  MixTypes,
  MixErrors,
 {$ifdef bTrace}
  MixCheck,
 {$endif bTrace}
  Windows,
  MixUtils,
  PlayerMain;

 {$R NoisyW.res}

begin
  try
    Run;
  except
    on E :Exception do 
      MessageBox(0, PTChar(E.Message), 'Error', MB_OK or MB_ICONERROR);
  end;
end.
