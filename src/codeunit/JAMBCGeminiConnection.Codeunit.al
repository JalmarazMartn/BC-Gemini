codeunit 69000 "JAM BC-Gemini Connection"
{
    procedure PostToGemini(ApiKey: Text; RequestBodyText: Text; URL: Text) ResponseText: Text
    var
        Conect1Err: Label 'HTTP Request failed with status code %1: %2';
        ComunicateErr: Label 'Failed to communicate with the Gemini API.';
        URLTok: Label 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=';
        Client: HttpClient;
        Headers: HttpHeaders;
        Content: HttpContent;
        Response: HttpResponseMessage;
        URLFinal: Text;
    begin
        // Construct the endpoint URL
        URLFinal := URL + '?key=' + ApiKey;

        // Prepare the HTTP body content and set Content-Type header
        Content.WriteFrom(RequestBodyText);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');

        // Make the POST request
        if Client.Post(URLFinal, Content, Response) then begin
            if Response.IsSuccessStatusCode() then begin
                Response.Content().ReadAs(ResponseText);
            end else begin
                Error(Conect1Err, Response.HttpStatusCode(), Response.ReasonPhrase());
            end;
        end else
            Error(ComunicateErr);
    end;

    procedure BuildStyleGuideRequestBody(PromptText: Text; SystemInstructionText: Text) RequestBodyText: Text
    var
        RootObj: JsonObject;
        ContentsArray: JsonArray;
        ContentObj: JsonObject;
        PartsArray: JsonArray;
        PartObj: JsonObject;

        // System Instruction variables
        SysInstructionObj: JsonObject;
        SysPartsArray: JsonArray;
        SysPartObj: JsonObject;

        // Schema variables
        GenConfigObj: JsonObject;
        ResponseSchemaObj: JsonObject;
        PropertiesObj: JsonObject;
        CumpleGuiaObj: JsonObject;
        SugerenciaObj: JsonObject;
        MayorErrorObj: JsonObject;
        RequiredArray: JsonArray;
    begin
        // 1. Build contents: [{ role: 'user', parts: [{ text: prompt }] }]
        PartObj.Add('text', PromptText);
        PartsArray.Add(PartObj);

        ContentObj.Add('role', 'user');
        ContentObj.Add('parts', PartsArray);

        ContentsArray.Add(ContentObj);
        RootObj.Add('contents', ContentsArray);

        // 2. Build systemInstruction: { parts: [{ text: systemInstructionText }] }
        if SystemInstructionText <> '' then begin
            SysPartObj.Add('text', SystemInstructionText);
            SysPartsArray.Add(SysPartObj);
            SysInstructionObj.Add('parts', SysPartsArray);
            RootObj.Add('systemInstruction', SysInstructionObj);
        end;

        // 3. Build responseSchema.properties
        CumpleGuiaObj.Add('type', 'INTEGER');
        CumpleGuiaObj.Add('description', 'Puntuación de 1 a 10');

        SugerenciaObj.Add('type', 'STRING');
        SugerenciaObj.Add('description', 'como debería haberse redactado mejor el texto: texto altenativo sin más explicaciones');

        MayorErrorObj.Add('type', 'STRING');
        MayorErrorObj.Add('description', 'Error principal');

        PropertiesObj.Add('CumpleGuia', CumpleGuiaObj);
        PropertiesObj.Add('Sugerencia', SugerenciaObj);
        PropertiesObj.Add('MayorError', MayorErrorObj);

        // 4. Build responseSchema required fields
        RequiredArray.Add('CumpleGuia');
        RequiredArray.Add('Sugerencia');
        RequiredArray.Add('MayorError');

        // 5. Assemble responseSchema
        ResponseSchemaObj.Add('type', 'OBJECT');
        ResponseSchemaObj.Add('properties', PropertiesObj);
        ResponseSchemaObj.Add('required', RequiredArray);

        // 6. Assemble generationConfig
        GenConfigObj.Add('responseMimeType', 'application/json');
        GenConfigObj.Add('responseSchema', ResponseSchemaObj);

        RootObj.Add('generationConfig', GenConfigObj);

        // Write final JSON object to output text variable
        RootObj.WriteTo(RequestBodyText);
    end;

    procedure ParseStyleResponse(ResponseText: Text; var CumpleGuia: Integer; var Sugerencia: Text; var MayorError: Text): Boolean
    var
        RootObj: JsonObject;
        CandidatesArray: JsonArray;
        CandidateToken: JsonToken;
        CandidateObj: JsonObject;
        ContentObj: JsonObject;
        PartsArray: JsonArray;
        PartToken: JsonToken;
        PartObj: JsonObject;

        // Variables para el JSON estructurado interno
        StructuredText: Text;
        StructuredObj: JsonObject;
        ValueToken: JsonToken;
        CR: Char;
        LF: Char;
    begin
        // Clear de las variables de salida
        Clear(CumpleGuia);
        Clear(Sugerencia);
        Clear(MayorError);

        // 1. Parsear la respuesta raíz de Gemini
        if not RootObj.ReadFrom(ResponseText) then
            exit(false);

        // Obtener "candidates"
        if not RootObj.Get('candidates', CandidateToken) then
            exit(false);
        CandidatesArray := CandidateToken.AsArray();

        if CandidatesArray.Count() = 0 then
            exit(false);

        // Obtener el primer candidato
        CandidatesArray.Get(0, CandidateToken);
        CandidateObj := CandidateToken.AsObject();

        // Obtener "content" -> "parts"
        if not CandidateObj.Get('content', ValueToken) then
            exit(false);
        ContentObj := ValueToken.AsObject();

        if not ContentObj.Get('parts', ValueToken) then
            exit(false);
        PartsArray := ValueToken.AsArray();

        if PartsArray.Count() = 0 then
            exit(false);

        // Obtener el primer "part" y extraer su "text"
        PartsArray.Get(0, PartToken);
        PartObj := PartToken.AsObject();

        if not PartObj.Get('text', ValueToken) then
            exit(false);

        StructuredText := ValueToken.AsValue().AsText();

        // 2. LIMPIEZA DE CARACTERES: Eliminar saltos de línea ("\n" o "n" sueltas) que corrompen el JSON interno
        CR := 13;
        LF := 10;
        StructuredText := StructuredText.Replace(Format(CR), '');
        StructuredText := StructuredText.Replace(Format(LF), '');
        StructuredText := StructuredText.Replace('\n', '');
        StructuredText := StructuredText.Replace('n' + Format(CR), '');
        StructuredText := StructuredText.Replace('n' + Format(LF), '');

        // 3. Parsear el JSON devuelto dentro del campo text
        if not StructuredObj.ReadFrom(StructuredText) then
            exit(false);

        // Extraer CumpleGuia
        if StructuredObj.Get('CumpleGuia', ValueToken) then
            CumpleGuia := ValueToken.AsValue().AsInteger();

        // Extraer Sugerencia
        if StructuredObj.Get('Sugerencia', ValueToken) then
            Sugerencia := ValueToken.AsValue().AsText();

        // Extraer MayorError
        if StructuredObj.Get('MayorError', ValueToken) then
            MayorError := ValueToken.AsValue().AsText();

        exit(true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Description', false, false)]
    local procedure CheckDescription(var Rec: Record "Gen. Journal Line")
    var
        StyleGuide: Record "JAM Style Guide";
        RequestBodyText: Text;
        ResponseText: Text;
        CumpleGuia: Integer;
        Sugerencia: Text;
        MayorError: Text;
    begin
        if rec.Description = '' then
            exit;
        if not StyleGuide.get(Rec.RecordId.TableNo, Rec.FieldNo(Description)) then
            exit;
        RequestBodyText := BuildStyleGuideRequestBody(rec.Description, StyleGuide.GetSystemPrompt());
        ResponseText := PostToGemini(StyleGuide."API Key", RequestBodyText, StyleGuide.URL);
        ParseStyleResponse(ResponseText, CumpleGuia, Sugerencia, MayorError);
        if CumpleGuia = 10 then
            exit;
        if not Confirm('Cumplimento de la guia de estilo %1.\Razón: %2\¿Desea sustituir por %3', true, CumpleGuia, MayorError, Sugerencia) then
            exit;
        rec.Description := CopyStr(Sugerencia, 1, MaxStrLen(rec.Description));
    end;
}