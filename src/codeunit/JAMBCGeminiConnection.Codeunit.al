codeunit 69000 "JAM BC-Gemini Connection"
{
    procedure PostToGemini(ApiKey: Text; RequestBodyText: Text) ResponseText: Text
    var
        Conect1Err: Label 'HTTP Request failed with status code %1: %2';
        ComunicateErr: Label 'Failed to communicate with the Gemini API.';
        URLTok: Label 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=';
        Client: HttpClient;
        Headers: HttpHeaders;
        Content: HttpContent;
        Response: HttpResponseMessage;
        Url: Text;
    begin
        // Construct the endpoint URL
        Url := URLTok + ApiKey;

        // Prepare the HTTP body content and set Content-Type header
        Content.WriteFrom(RequestBodyText);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');

        // Make the POST request
        if Client.Post(Url, Content, Response) then begin
            if Response.IsSuccessStatusCode() then begin
                Response.Content().ReadAs(ResponseText);
            end else begin
                Error(Conect1Err, Response.HttpStatusCode(), Response.ReasonPhrase());
            end;
        end else
            Error(ComunicateErr);
    end;

    procedure BuildRequestBody(PromptText: Text; SystemInstructionText: Text) RequestBodyText: Text
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
}