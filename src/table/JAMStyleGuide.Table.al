table 69000 "JAM Style Guide"
{
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Table No."; Integer)
        {
            NotBlank = true;
        }
        field(2; "Field No."; Integer)
        {
            NotBlank = true;
        }
        field(3; "System Prompt"; Blob)
        {
        }
        field(4; URL; Text[250])
        {

        }
        field(5; "API Key"; Text[100])
        {
            MaskType = Concealed;
        }
    }
    keys
    {
        key(PK; "Table No.", "Field No.")
        { }
    }
    procedure SetSystemPrompt(NewWorkDescription: Text)
    var
        OutStream: OutStream;
    begin
        Clear("System Prompt");
        "System Prompt".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(NewWorkDescription);
        Modify();
    end;

    procedure GetSystemPrompt() WorkDescription: Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("System Prompt");
        "System Prompt".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), FieldName("System Prompt")));
    end;
}
