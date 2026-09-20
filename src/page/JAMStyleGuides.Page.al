page 69000 "JAM Style Guides"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "JAM Style Guide";
    Editable = false;
    CardPageId = "JAM Style Guide Card";
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Table No."; Rec."Table No.")
                {
                    ToolTip = 'Specifies the value of the Table No. field.', Comment = '%';
                }
                field("Field No."; Rec."Field No.")
                {
                    ToolTip = 'Specifies the value of the Field No. field.', Comment = '%';
                }
                field("System Prompt"; Rec.GetSystemPrompt())
                {
                    ToolTip = 'Specifies the value of the System Prompt field.', Comment = '%';
                }
                field(URL; Rec.URL)
                {
                    ToolTip = 'Specifies the value of the URL field.', Comment = '%';
                }
                field("API Key"; Rec."API Key")
                {
                    ToolTip = 'Specifies the value of the API Key field.', Comment = '%';
                }
            }
        }
        area(Factboxes)
        {

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
}