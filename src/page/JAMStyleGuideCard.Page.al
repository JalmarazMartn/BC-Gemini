page 69001 "JAM Style Guide Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "JAM Style Guide";

    layout
    {
        area(Content)
        {
            group(GroupName)
            {

                field("Table No."; Rec."Table No.")
                {
                    ToolTip = 'Specifies the value of the Table No. field.', Comment = '%';
                }
                field("Field No."; Rec."Field No.")
                {
                    ToolTip = 'Specifies the value of the Field No. field.', Comment = '%';
                }
                field(URL; Rec.URL)
                {
                    ToolTip = 'Specifies the value of the URL field.', Comment = '%';
                }
                field("API Key"; Rec."API Key")
                {
                    ToolTip = 'Specifies the value of the API Key field.', Comment = '%';
                }
                group("Sytem Prompt")
                {
                    Caption = 'Sytem Prompt';
                    field(WorkDescription; SystemPrompt)
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        MultiLine = true;
                        ShowCaption = false;
                        ToolTip = 'Specifies the products or service being offered.';

                        trigger OnValidate()
                        begin
                            Rec.SetSystemPrompt(SystemPrompt);
                        end;
                    }
                }
                group(Test)
                {
                    field(ImputTest; ImputTest)
                    {
                        trigger OnAssistEdit()
                        var
                        begin

                        end;
                    }
                }

            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {

                trigger OnAction()
                begin

                end;
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        SystemPrompt := Rec.GetSystemPrompt();
    end;

    var
        SystemPrompt: text;
        ImputTest: Text;
}