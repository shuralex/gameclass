unit GClangutils;

interface

procedure GCLanguageLoadDefault;

function translate(inp:string):string; // ������� �����
function translate_back(inp:string):string; // �������� ������� �����

procedure GCSaveLang(curFile:string);
procedure GCPhraseAdd(str:string);

procedure GCReadLang(f:integer);
function GCReadWideString(f:integer):WideString;
procedure GCWriteWideString(f:integer;str:widestring);
procedure GCPhraseDelete(index: integer);
function GetPhraseIndex(str:widestring):integer;

const words_count = 1000; // ���������� ����, ������� �� ����� ����������!
type
  TPhrases = array[0..999, 0..2] of WideString; // ������ ������ :)

var
  Phrases: TPhrases; // ��� ����� - ������
  countPhrases: integer = 0; // ����� ����
  currentPhrase: integer = -1; // ������� ������������� �����

  traLang:integer = 1; // �� ��������� ������� ����������
  // 1 - English
  // 2 - Other
  
implementation

uses
  GCConst,
  SysUtils, Windows, uSystemRegistryTools;

// ������� ���������� ������� ����� inp �� ������� ����
// ���� ����� ����������, �� ���������� '_unknown_'
function translate(inp:string):string;
var 
  i: integer;
//  s: string;
  fuckflag: boolean; 
begin
 translate := '_unknown_'; 
 fuckflag := true;
 for i:=0 to countPhrases-1 do
 begin
//  s := Phrases[i,0];
  if ( Phrases[i,0] = inp ) then 
  begin
    translate := Phrases[i,traLang];
    fuckflag := false;
  end;
 end;
 // ���� ��������� ����� �����, �� ���� ��������� ��� ��� ����� ����� �����
 // ��������� � ������� GCLanguage.exe 
 if (fuckflag) then
 begin
   GCPhraseAdd(inp);
   GCSaveLang(LANGUAGE_FILENAME);
 end;
end;

// ������� ���������� �������� ������� ����� � �������� �����
function translate_back(inp:string):string;
var 
  i: integer;
begin
 translate_back := ''; 
 for i:=0 to countPhrases-1 do
  if ( Phrases[i,traLang] = inp ) then 
    translate_back := Phrases[i,0];
end;

procedure GCPhraseAdd(str:string);
begin
  Phrases[countPhrases,0] := str;
  Phrases[countPhrases,1] := '';
  Phrases[countPhrases,2] := '';    
  countPhrases := countPhrases +1;
end;

procedure GCSaveLang(curFile:string);
var
  f:integer;  // file handle
  i:integer;
  str:WideString;
  len:integer;
begin
  f := FileCreate(curFile);
  if not (f>0) then
  begin
    MessageBox(HWND_TOP,'Lng-file save error','Error',MB_OK or MB_ICONERROR);
    exit;
  end;
  // write (c)header of file
  str := 'Generated by GCLanguage Center (C) Dmitry Novikov 2002';
  GCWriteWideString(f,str);
  // write count of phrases
  len := countPhrases;
  FileWrite(f, len , SizeOf(len));
  // write phrases
  for i:=0 to countPhrases-1 do
  begin
    // write phrase key
    GCWriteWideString(f,Phrases[i,0]);
    // write phrase eng
    GCWriteWideString(f,Phrases[i,1]);
    // write phrase other lang
    GCWriteWideString(f,Phrases[i,2]);    
  end;
  FileClose(f);
  // end write
end;

// read wide string to file
function GCReadWideString(f:integer):WideString;
var
  i,len:integer;
  str:WideString;
  str2: WideChar;
begin
  FileRead(f,len,SizeOf(Len)); 
  str := '';
  for i:=1 to len do
  begin
    FileRead(f,str2,SizeOf(str2));
    str := str + str2;
  end;
  GCReadWideString := str;  
end;

// write wide string to file
procedure GCWriteWideString(f:integer; str:widestring);
var
  i,len:integer;
  str2: WideChar;  
begin
  len := Length(str);
  FileWrite(f,len,SizeOf(len));
  for i:=1 to length(str) do
  begin    
    str2 := str[i];
    FileWrite(f,str2,sizeof(str2));
  end;
end;

// return index from Phrases massive of str
function GetPhraseIndex(str:widestring):integer;
var
  i:integer;
begin
  GetPhraseIndex := -1;
  for i:=0 to countPhrases-1 do
  begin
    if (Phrases[i,0] = str) then
    begin
      GetPhraseIndex := i;
      break;
    end;
  end;
end;

// delete phrase from phrases array
procedure GCPhraseDelete(index:integer);
var
  i:integer;
begin
  if (index = -1) then exit;
  // delete phrase from massive
  for i:=index+1 to countPhrases-1 do
  begin
    Phrases[i-1,0] := Phrases[i,0];
    Phrases[i-1,1] := Phrases[i,1];
    Phrases[i-1,2] := Phrases[i,2];        
  end;
  countPhrases := countPhrases - 1;
end;

// read lng-file
procedure GCReadLang(f:integer);
var
  str:widestring;
  len,i:integer;
begin
  // read (c)header of file
  str := GCReadWideString(f);
  // read count of phrases
  FileRead(f,len,SizeOf(len));
  // read phrases
  countPhrases := 0;
  for i:=0 to len-1 do
  begin
    // read phrase key
    str := GCReadWideString(f);
    //lbPhrases.Items.Add(str);
    Phrases[countPhrases,0] := str;    
    // write phrase eng
    Phrases[countPhrases,1] := GCReadWideString(f);    
    // write phrase other lang
    Phrases[countPhrases,2] := GCReadWideString(f);
    // next phrase
    countPhrases := countPhrases +1;
  end;
end;
  
procedure GCLanguageLoadDefault;
var
  f:integer;
  n: integer;
begin
  // lng file
  f := FileOpen(LANGUAGE_FILENAME, fmOpenRead or fmShareDenyNone);
  if not (f > 0) then
  begin
    MessageBox(HWND_TOP,'Warning, language-file GCServer.lng not found! See error #1 in help','Starting error...',MB_OK or MB_ICONERROR);
    exit;
  end;
  GCReadLang(f);
  FileClose(f);

  traLang := GCCommonRegistryReadInt('Lng');
  if (traLang < 1) or (traLang > 2) then traLang := 1;
end;

end.
