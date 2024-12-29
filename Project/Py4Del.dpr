program Py4Del;

uses
  System.StartUpCopy,
  FMX.Forms,
  Py4Del.View.Main in '..\Src\View\Py4Del.View.Main.pas' {FrmMain},
  Py4Del.Utils.PyThread in '..\Src\Utils\Py4Del.Utils.PyThread.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
