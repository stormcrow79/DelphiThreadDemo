unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,
  StdCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
  private
    procedure TaskComplete(Sender: TObject);
    procedure HandleCheckpoint1(Sender: TObject);
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

type
  TSpecificTaskThread = Class(TThread)
  private
    FInterimResult: string;
    FFinalResult: string;

    FOnCheckpoint1: TNotifyEvent;

  protected
    procedure DoCheckpoint1;
    procedure Execute; override;
  public
    property InterimResult: string read FInterimResult;
    property FinalResult: string read FFinalResult;
    property OnCheckpoint1 : TNotifyEvent read FOnCheckpoint1 write FOnCheckpoint1;
  End;

procedure TSpecificTaskThread.DoCheckpoint1;
begin
  if Assigned(FOnCheckpoint1) then FOnCheckpoint1(Self);
end;

procedure TSpecificTaskThread.Execute;
var
  aGuid: TGuid;
begin
  FInterimResult := '';
  FFinalResult := '';

  // call an external API (web, Hydra etc here)
  Sleep(1500);

  CreateGuid(aGuid);
  FInterimResult := GuidToString(aGuid);
  Synchronize(DoCheckpoint1);

  // call an external API (web, Hydra etc here)
  Sleep(1500);

  CreateGuid(aGuid);
  FFinalResult := GuidToString(aGuid);
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  oThread : TSpecificTaskThread;
begin
  // True tells the thread not to start until we've configured it
  oThread := TSpecificTaskThread.Create(True);
  // OnCheckpoint1 is called on the UI thread at an intermediate progress event
  oThread.OnCheckpoint1 := HandleCheckpoint1;
  // OnTerminate is called on the UI thread after Execute completes
  oThread.OnTerminate := TaskComplete;
  // don't need this if we hang onto oThread and free it
  oThread.FreeOnTerminate := True;

  oThread.Resume;
  Memo1.Lines.Add(Format('%s - thread started', [DateTimeToStr(Now)]));
end;

procedure TForm1.HandleCheckpoint1(Sender: TObject);
var
  value: string;
begin
  value := TSpecificTaskThread(Sender).InterimResult;
  Memo1.Lines.Add(Format('%s - checkpoint, result ''%s''', [DateTimeToStr(Now), value]));
end;

procedure TForm1.TaskComplete(Sender: TObject);
var
  value: string;
begin
  value := TSpecificTaskThread(Sender).FinalResult;
  Memo1.Lines.Add(Format('%s - thread finished, result ''%s''', [DateTimeToStr(Now), value]));
end;

end.
