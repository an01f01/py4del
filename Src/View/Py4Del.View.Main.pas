unit Py4Del.View.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.StdCtrls, FMX.Objects, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  FMX.Edit, PythonEngine, Py4Del.Utils.PyThread, FMX.PythonGUIInputOutput;

type
  TFrmMain = class(TForm)
    MmConsole: TMemo;
    MmPyCode: TMemo;
    RctToolbar: TRectangle;
    Splitter1: TSplitter;
    EdtPath: TEdit;
    BtnBrowse: TButton;
    BtnRun: TButton;
    BtnStop: TButton;
    PythonEngine1: TPythonEngine;
    PythonModule1: TPythonModule;
    procedure BtnRunClick(Sender: TObject);
    procedure BtnStopClick(Sender: TObject);
    procedure BtnBrowseClick(Sender: TObject);
    procedure OnPyModuleLoad(Sender: TObject);
  private
    { Private declarations }
    OwnThreadState: PPyThreadState;
    ThreadsRunning: Integer;

    function ConsoleModule_Print( pself, args : PPyObject ) : PPyObject; cdecl;
    procedure InitThreads(ThreadExecMode: TThreadExecMode; script: TStrings);
    procedure ThreadDone(Sender: TObject);
  public
    { Public declarations }
    Thread1: TPyThread;
  end;

var
  FrmMain: TFrmMain;

implementation


{$R *.fmx}

procedure TFrmMain.InitThreads(ThreadExecMode: TThreadExecMode; script: TStrings);
begin
  ThreadsRunning := 1;
  with GetPythonEngine do
  begin
    OwnThreadState := PyEval_SaveThread;

    Thread1 := TPyThread.Create( ThreadExecMode, script, PythonModule1, 'print_data',
                           MmConsole);
    Thread1.OnTerminate := ThreadDone;
  end;

  BtnRun.Enabled := False;

end;

procedure TFrmMain.BtnBrowseClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(self);

  OpenDlg.InitialDir := GetCurrentDir;
  OpenDlg.Filter := 'Python file|*.py';

  if OpenDlg.Execute and FileExists(OpenDlg.FileName) then begin
    EdtPath.Text := OpenDlg.FileName;
    MmPyCode.Lines.LoadFromFile(OpenDlg.FileName);
    BtnRun.Enabled := True;
  end;

  OpenDlg.Free;
end;

procedure TFrmMain.BtnRunClick(Sender: TObject);
begin
  BtnStop.Enabled := True;
  InitThreads(emNewInterpreterOwnGIL, MmPyCode.Lines);
end;

procedure TFrmMain.BtnStopClick(Sender: TObject);
begin
  if Assigned(Thread1) and not Thread1.Finished then Thread1.Stop();
end;

function TFrmMain.ConsoleModule_Print( pself, args : PPyObject ) : PPyObject; cdecl;
var
  pprint: NativeInt;
  val1: Integer;
  val2: Single;
  val3: PAnsiChar;
begin
  with GetPythonEngine do
  begin
    if (PyErr_Occurred() = nil) and
{$IFDEF CPU64BITS}
      (PyArg_ParseTuple( args, 'Lifs',@pprint, @val1, @val2, @val3) <> 0)
{$ELSE}
      (PyArg_ParseTuple( args, 'iifs',@pprint, @val1, @val2, @val3) <> 0)
{$ENDIF}
    then
    begin
      TPyThread(pprint).ConsoleUpdate(val1, val2, val3);
      Result := ReturnNone;
    end else
      Result := nil;
  end;

end;

procedure TFrmMain.ThreadDone(Sender: TObject);
begin
  Dec(ThreadsRunning);
  if ThreadsRunning = 0 then
  begin
    GetPythonEngine.PyEval_RestoreThread(OwnThreadState);
    BtnRun.Enabled := True;
    BtnStop.Enabled := False;
    Thread1 := nil;
  end;
end;

procedure TFrmMain.OnPyModuleLoad(Sender: TObject);
begin
  with Sender as TPythonModule do
    begin
      AddDelphiMethod( 'printme',
                       ConsoleModule_Print,
                       'printme(handle,val1,val2,val3)');
    end;
end;

end.
