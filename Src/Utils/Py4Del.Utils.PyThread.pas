unit Py4Del.Utils.PyThread;

interface

uses
  Types, Classes, System.SysUtils, FMX.Memo, PythonEngine;

type

  TPyThread = class (TPythonThread)
  private
    FModule: TPythonModule;
    FScript: TStrings;
    FMmConsole: TMemo;
    FVal1: Integer;
    FVal2: Single;
    FVal3: string;
    Fpyfuncname: string;
    FRunning : Boolean;

    procedure DoConsoleUpdate;

  protected
    procedure ExecuteWithPython; override;
  public

    constructor Create( AThreadExecMode: TThreadExecMode; script: TStrings;
                        module: TPythonModule; apyfuncname: string;
                        MmConsole: TMemo);

    procedure ConsoleUpdate(Val1: Integer; Val2: Single; Val3: string);
    procedure Stop;

  end;

implementation

{ TPyThread }

constructor TPyThread.Create( AThreadExecMode: TThreadExecMode; script: TStrings;
                                module: TPythonModule; apyfuncname: string;
                                MmConsole: TMemo);
begin
  Fpyfuncname := apyfuncname;
  FScript := script;
  FMmConsole := MmConsole;
  FModule := module;
  FreeOnTerminate := True;
  ThreadExecMode := AThreadExecMode;
  inherited Create(False);
end;

{ Since DoConsoleUpdate uses a TMemo component, it should never
  be called directly by this thread.  DoConsoleUpdate should be called by passing
  it to the Synchronize method which causes DoConsoleUpdate to be executed by the
  main thread, avoiding multi-thread conflicts. See ConsoleUpdate for an
  example of calling Synchronize. }

procedure TPyThread.DoConsoleUpdate;
begin
  FMmConsole.Lines.Add((IntToStr(FVal1) + ': ' + FloatToStr(FVal2) + ', ' + FVal3));
end;

{ ConsoleUpdate is a wrapper on DoConsoleUpdate making it easier to use.  The
  parameters are copied to instance variables so they are accessable
  by the main thread when it executes DoConsoleUpdate }

procedure TPyThread.ConsoleUpdate(Val1: Integer; Val2: Single; Val3: string);
begin
  Py_BEGIN_ALLOW_THREADS;
  if Terminated then
    raise EPythonError.Create( 'Pythonthread terminated');
  FVal1 := Val1;
  FVal2 := Val2;
  FVal3 := Val3;
  Synchronize(DoConsoleUpdate);
  Py_END_ALLOW_THREADS;
end;

{ The Execute method is called when the thread starts }

procedure TPyThread.ExecuteWithPython;
var pyfunc: PPyObject;
begin
  FRunning := true;
  try
    with GetPythonEngine do
    begin
      if Assigned(FModule) and (ThreadExecMode <> emNewState) then
        FModule.InitializeForNewInterpreter;
      if Assigned(fScript) then
      try
        ExecStrings(fScript);
      except
      end;
      pyfunc :=  FindFunction(ExecModule, utf8encode(fpyfuncname));
      if Assigned(pyfunc) then
        try
          EvalFunction(pyfunc,[NativeInt(self)]);
        except
        end;
      Py_XDecRef(pyfunc);
    end;
  finally
    FRunning := false;
  end;
end;

{ Stops the thread }
procedure TPyThread.Stop;
begin
  with GetPythonEngine do
  begin
    if FRunning then
    begin
      PyEval_AcquireThread(self.ThreadState);
      PyErr_SetString(PyExc_KeyboardInterrupt^, 'Terminated');
      PyEval_ReleaseThread(self.ThreadState);
    end;
  end;
end;
end.
