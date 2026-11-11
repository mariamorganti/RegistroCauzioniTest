USE  [DBRegistroCauzioni]
GO

/****** Lookup tipi documento del Fascicolo Digitale con riferimento ai template di lettera ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- TABELLA: RegistroCauzioneTipoDocumento
-- SCOPO: Definisce tutti i tipi di documento gestibili nel Fascicolo Digitale
--        della Scheda Cauzione, con riferimento al template Word da cui vengono
--        generati (sezione 3.5.1 TO BE "Modelli di Lettera").
--
-- SOSTITUISCE: Il riferimento a [dbo].[DocTipoDocumento] nella vecchia architettura
--        (DocFascicolo). La nuova tabella è specifica per il dominio Cauzioni,
--        più semplice e collegata direttamente ai template di sezione.
--
-- RELAZIONE: Il campo [IDTipoDocumento] di [RegistroCauzioniFascicoloDigitale]
--        fa riferimento all'[ID] di questa tabella tramite FK.
--
-- ID è IDENTITY(1,1): la tabella RegistroCauzioniFascicoloDigitale usa questo ID
--        come chiave esterna per identificare il tipo di documento caricato.
--
-- CAMPI PEC (sezione 3.5.4 TO BE "Invio PEC dall'Applicazione"):
--   PecOggetto, PecCorpo, PecFirma sono testi predefiniti associati al tipo di
--   documento che l'applicazione usa per pre-compilare la maschera di invio PEC.
--   L'operatore può modificarli prima dell'invio definitivo.
--   Supportano segnaposto risolti a runtime dal motore di composizione:
--     {NumIns}             numero inserimento cauzione
--     {AnnoIns}            anno inserimento cauzione
--     {NPolizza}           numero polizza/fideiussione
--     {RagioneSociale}     ragione sociale del beneficiario
--     {DenomFideiussore}   denominazione del fideiussore
--     {AgenziaFideiussore} denominazione dell'agenzia fideiussore
--     {ScadenzaPolizza}    data scadenza polizza (formato gg/mm/aaaa)
--     {ImpTotale}          importo totale garantito (formato valuta)
--     {DataOggi}           data odierna (formato gg/mm/aaaa)
--     {NomeUfficio}        nome ufficio mittente (da configurazione di sistema)
--     {FirmaUfficio}       blocco firma ufficio (da configurazione di sistema)
-- =============================================

CREATE TABLE [dbo].[RegistroCauzioneTipoDocumento](
    [ID]                    [int]           IDENTITY(1,1) NOT NULL,
    [CodTipoDocumento]      [nvarchar](80)  NOT NULL,  -- codice breve univoco, es: LETTERA_CONFERMA_VALIDITA
    [CodSezione]            [nvarchar](30)  NOT NULL,  -- sezione di pertinenza: GENERALE, CONVALIDA, VARIAZIONI, PROROGHE, SVINCOLO, ESCUSSIONE
    [Descrizione]           [nvarchar](300) NOT NULL,  -- descrizione leggibile per l'interfaccia
    [NomeTemplateFile]      [nvarchar](500) NULL,      -- nome del file template, es: Template_Lettera_Conferma_Validita.docx
    [DescrizioneTemplate]   [nvarchar](500) NULL,      -- descrizione estesa del contenuto/scopo del template
    [IsObbligatorio]        [bit]           NOT NULL CONSTRAINT [DF_RCTipoDoc_IsObbligatorio] DEFAULT (0),
    -- 1 = documento obbligatorio per completare la sezione
    [IsGeneratoAutomatico]  [bit]           NOT NULL CONSTRAINT [DF_RCTipoDoc_IsGeneratoAuto] DEFAULT (1),
    -- 1 = generabile da template, 0 = solo upload manuale (es: documento esterno)
    [IsPecObbligatoria]     [bit]           NOT NULL CONSTRAINT [DF_RCTipoDoc_IsPecObbligatoria] DEFAULT (0),
    -- 1 = il documento deve essere trasmesso obbligatoriamente via PEC (non solo firmato e archiviato)

    -- ---- Composizione PEC (sezione 3.5.4 Invio PEC dall'Applicazione) ----
    -- Campi NON obbligatori: NULL = nessun testo predefinito, l'operatore compila manualmente.
    -- Se valorizzati, l'applicazione pre-compila la maschera PEC; l'operatore può modificare
    -- il testo prima dell'invio. I segnaposto {…} sono risolti a runtime.
    [PecOggetto]            [nvarchar](500) NULL,      -- oggetto predefinito della PEC
    [PecCorpo]              [nvarchar](max) NULL,      -- corpo predefinito della PEC (testo libero, multiriga)
    [PecFirma]              [nvarchar](max) NULL,      -- blocco firma predefinito da accodare al corpo

    [Ordine]                [int]           NOT NULL CONSTRAINT [DF_RCTipoDoc_Ordine] DEFAULT (0),
    [DataInizioValidita]    [datetime2](7)  NOT NULL CONSTRAINT [DF_RCTipoDoc_DataIV] DEFAULT (SYSDATETIME()),
    [DataFineValidita]      [datetime2](7)  NOT NULL CONSTRAINT [DF_RCTipoDoc_DataFV] DEFAULT (CONVERT(datetime2, '9999-12-31')),
    [DataModifica]          [datetime2](7)  NOT NULL CONSTRAINT [DF_RCTipoDoc_DataModifica] DEFAULT (SYSDATETIME()),
    [IDOperatore]           [int]           NOT NULL,

 CONSTRAINT [PK_RegistroCauzioneTipoDocumento] PRIMARY KEY CLUSTERED
(
    [ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
       ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90,
       OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [UQ_RCTipoDoc_CodTipoDocumento] UNIQUE NONCLUSTERED
(
    [CodTipoDocumento] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
       ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[RegistroCauzioneTipoDocumento] WITH NOCHECK ADD CONSTRAINT [CK_RCTipoDoc_CodSezione]
    CHECK ([CodSezione] IN (N'GENERALE', N'CONVALIDA', N'VARIAZIONI', N'PROROGHE', N'SVINCOLO', N'ESCUSSIONE'))
GO
ALTER TABLE [dbo].[RegistroCauzioneTipoDocumento] CHECK CONSTRAINT [CK_RCTipoDoc_CodSezione]
GO

-- =============================================
-- DATI: Tipi documento / Template (sezione 3.5.1 Modelli di Lettera)
-- =============================================

-- ---- Sezione GENERALE ----
INSERT INTO [dbo].[RegistroCauzioneTipoDocumento]
    ([CodTipoDocumento],[CodSezione],[Descrizione],[NomeTemplateFile],[DescrizioneTemplate],[IsObbligatorio],[IsGeneratoAutomatico],[Ordine],[IDOperatore])
VALUES
(N'RIEPILOGO_CAUZIONE',          N'GENERALE',   N'Scheda riepilogativa della cauzione',                   N'Template_Riepilogo_Cauzione.docx',                 N'Scheda sintetica con tutti i dati principali della cauzione, importi e stato attuale.',                              0, 1,  10, 1),
(N'CHECKLIST_CONTROLLO',         N'GENERALE',   N'Check-list di controllo generale',                      N'Template_CheckList_Controllo.docx',                N'Lista di controllo per la verifica della completezza e correttezza della documentazione.',                           0, 1,  20, 1),
(N'DOCUMENTO_ESTERNO_GENERICO',  N'GENERALE',   N'Documento esterno (upload manuale)',                     NULL,                                                N'Documento caricato manualmente dall''utente, non generato da template (es: corrispondenza ricevuta).',              0, 0,  99, 1);

-- ---- Sezione CONVALIDA ----
INSERT INTO [dbo].[RegistroCauzioneTipoDocumento]
    ([CodTipoDocumento],[CodSezione],[Descrizione],[NomeTemplateFile],[DescrizioneTemplate],[IsObbligatorio],[IsGeneratoAutomatico],[Ordine],[IDOperatore])
VALUES
(N'CHECKLIST_CONTROLLO_CONVALIDA',    N'CONVALIDA', N'Check-list di controllo per la convalida',              N'Template_CheckList_Controllo_Convalida.docx',      N'Lista di controllo per la verifica formale e sostanziale della polizza fideiussoria ricevuta.',                       1, 1,  10, 1),
(N'LETTERA_CONFERMA_VALIDITA',        N'CONVALIDA', N'Lettera di conferma validità polizza fideiussoria',      N'Template_Lettera_Conferma_Validita.docx',          N'Lettera ufficiale al fideiussore che conferma la validità e la conformità della polizza ricevuta.',                  1, 1,  20, 1),
(N'SOLLECITO_INFORMALE_VALIDITA',     N'CONVALIDA', N'Primo sollecito informale per documentazione mancante',  N'Template_Sollecito_Informale_Validita.docx',       N'Comunicazione informale per richiedere documentazione integrativa o correzioni minori alla polizza.',               0, 1,  30, 1),
(N'SOLLECITO_FORMALE_VALIDITA',       N'CONVALIDA', N'Sollecito formale per documentazione mancante',          N'Template_Sollecito_Formale_Validita.docx',         N'Sollecito formale (secondo o terzo invio) per documentazione mancante o non conforme, con indicazione di scadenza.',  0, 1,  40, 1),
(N'LETTERA_NON_CONFORMITA',           N'CONVALIDA', N'Comunicazione di non conformità della polizza',          N'Template_Lettera_Non_Conformita.docx',             N'Lettera che comunica al fideiussore le motivazioni di non conformità e le azioni correttive richieste.',             0, 1,  50, 1),
(N'LETTERA_INTEGRAZIONE_RICHIESTA',   N'CONVALIDA', N'Richiesta di integrazione/rettifica documentale',        N'Template_Lettera_Integrazione_Richiesta.docx',    N'Richiesta formale di integrazione o rettifica della documentazione inviata dal fideiussore.',                       0, 1,  60, 1),
(N'LETTERA_INVALIDAZIONE',            N'CONVALIDA', N'Comunicazione di invalidazione della polizza',           N'Template_Lettera_Invalidazione.docx',              N'Lettera ufficiale che comunica l''invalidazione della polizza e richiede la sostituzione.',                          0, 1,  70, 1),
(N'POLIZZA_ORIGINALE',                N'CONVALIDA', N'Polizza/fideiussione originale (upload)',                 NULL,                                                N'Documento originale ricevuto dal fideiussore, caricato manualmente dopo la ricezione fisica o via PEC.',             1, 0,  80, 1);

-- ---- Sezione VARIAZIONI ----
INSERT INTO [dbo].[RegistroCauzioneTipoDocumento]
    ([CodTipoDocumento],[CodSezione],[Descrizione],[NomeTemplateFile],[DescrizioneTemplate],[IsObbligatorio],[IsGeneratoAutomatico],[Ordine],[IDOperatore])
VALUES
(N'LETTERA_RICHIESTA_VARIAZIONE',     N'VARIAZIONI', N'Richiesta di modifica del contratto al fideiussore',  N'Template_Lettera_Richiesta_Variazione.docx',       N'Lettera formale al fideiussore per richiedere la modifica di importo, durata o altri elementi contrattuali.',           1, 1,  10, 1),
(N'LETTERA_CONFERMA_VARIAZIONE',      N'VARIAZIONI', N'Conferma dell''avvenuta variazione contrattuale',      N'Template_Lettera_Conferma_Variazione.docx',        N'Lettera che conferma la ricezione e la validazione del documento di variazione contrattuale.',                        1, 1,  20, 1),
(N'LETTERA_RIFIUTO_VARIAZIONE',       N'VARIAZIONI', N'Comunicazione di non accettazione della variazione',   N'Template_Lettera_Rifiuto_Variazione.docx',         N'Comunicazione al fideiussore di rifiuto della variazione proposta, con motivazione e indicazione della procedura alternativa.', 0, 1, 30, 1),
(N'APPENDICE_CONTRATTUALE',           N'VARIAZIONI', N'Appendice/atto di variazione contrattuale (upload)',   NULL,                                                N'Documento di variazione contrattuale ricevuto dal fideiussore, caricato manualmente.',                               1, 0,  40, 1);

-- ---- Sezione PROROGHE ----
INSERT INTO [dbo].[RegistroCauzioneTipoDocumento]
    ([CodTipoDocumento],[CodSezione],[Descrizione],[NomeTemplateFile],[DescrizioneTemplate],[IsObbligatorio],[IsGeneratoAutomatico],[Ordine],[IDOperatore])
VALUES
(N'COMUNICAZIONE_PROROGA_PROGETTO',   N'PROROGHE', N'Comunicazione di proroga del progetto al fideiussore',  N'Template_Comunicazione_Proroga_Progetto.docx',    N'Lettera che comunica al fideiussore la proroga del progetto e l''esigenza di estendere la copertura fideiussoria.',     1, 1,  10, 1),
(N'LETTERA_RICHIESTA_RINNOVO',        N'PROROGHE', N'Richiesta formale di rinnovo/proroga della polizza',    N'Template_Lettera_Richiesta_Rinnovo.docx',          N'Lettera formale al fideiussore per richiedere il rinnovo o la proroga della polizza con indicazione della nuova scadenza.', 1, 1, 20, 1),
(N'LETTERA_CONFERMA_PROROGA',         N'PROROGHE', N'Conferma dell''avvenuta proroga della polizza',          N'Template_Lettera_Conferma_Proroga.docx',           N'Lettera che conferma la ricezione e la validazione del documento di proroga/rinnovo ricevuto dal fideiussore.',           1, 1,  30, 1),
(N'LETTERA_RIFIUTO_PROROGA',          N'PROROGHE', N'Comunicazione di rifiuto proroga da parte del fideiussore', N'Template_Lettera_Rifiuto_Proroga.docx',        N'Comunicazione che registra il rifiuto della proroga da parte del fideiussore e avvia la procedura alternativa.',          0, 1,  40, 1),
(N'DOCUMENTO_RINNOVO_POLIZZA',        N'PROROGHE', N'Documento di rinnovo/proroga polizza (upload)',           NULL,                                                N'Documento di rinnovo o proroga ricevuto dal fideiussore, caricato manualmente dopo la ricezione.',                       1, 0,  50, 1);

-- ---- Sezione SVINCOLO ----
INSERT INTO [dbo].[RegistroCauzioneTipoDocumento]
    ([CodTipoDocumento],[CodSezione],[Descrizione],[NomeTemplateFile],[DescrizioneTemplate],[IsObbligatorio],[IsGeneratoAutomatico],[Ordine],[IDOperatore])
VALUES
(N'LETTERA_AUTORIZZAZIONE_SVINCOLO_PARZIALE', N'SVINCOLO', N'Autorizzazione svincolo parziale',              N'Template_Lettera_Autorizzazione_Svincolo_Parziale.docx', N'Lettera che autorizza lo svincolo parziale della fideiussione, con indicazione dell''importo da svincolare.',           0, 1,  10, 1),
(N'LETTERA_AUTORIZZAZIONE_SVINCOLO_TOTALE',   N'SVINCOLO', N'Autorizzazione svincolo totale',                N'Template_Lettera_Autorizzazione_Svincolo_Totale.docx',   N'Lettera che autorizza lo svincolo totale della fideiussione a conclusione del procedimento.',                           1, 1,  20, 1),
(N'LETTERA_COMUNICAZIONE_SVINCOLO',           N'SVINCOLO', N'Comunicazione di svincolo al fideiussore',      N'Template_Lettera_Comunicazione_Svincolo.docx',           N'Lettera ufficiale al fideiussore che comunica il nulla osta allo svincolo e indica le modalità operative.',              1, 1,  30, 1),
(N'CONFERMA_SVINCOLO_FIDEIUSSORE',            N'SVINCOLO', N'Conferma svincolo da fideiussore (upload)',      NULL,                                                      N'Documento di conferma dell''avvenuto svincolo ricevuto dal fideiussore.',                                               0, 0,  40, 1);

-- ---- Sezione ESCUSSIONE ----
INSERT INTO [dbo].[RegistroCauzioneTipoDocumento]
    ([CodTipoDocumento],[CodSezione],[Descrizione],[NomeTemplateFile],[DescrizioneTemplate],[IsObbligatorio],[IsGeneratoAutomatico],[Ordine],[IDOperatore])
VALUES
(N'AVVISO_DEBITORE',                  N'ESCUSSIONE', N'Avviso al beneficiario/debitore',                     N'Template_Avviso_Debitore.docx',                    N'Comunicazione formale al beneficiario del procedimento di escussione avviato nei suoi confronti.',                      1, 1,  10, 1),
(N'AVVISO_GARANTE',                   N'ESCUSSIONE', N'Avviso al fideiussore/garante',                        N'Template_Avviso_Garante.docx',                     N'Comunicazione formale al fideiussore dell''avvio del procedimento di escussione.',                                      1, 1,  20, 1),
(N'LETTERA_ESCUSSIONE',               N'ESCUSSIONE', N'Lettera formale di escussione',                        N'Template_Lettera_Escussione.docx',                 N'Lettera formale con cui si richiede al fideiussore il pagamento dell''importo escusso.',                               1, 1,  30, 1),
(N'LETTERA_RESTITUZIONE_RESIDUO',     N'ESCUSSIONE', N'Lettera di restituzione/rimborso residuo post-escussione', N'Template_Lettera_Restituzione_Residuo.docx',  N'Lettera che comunica la chiusura del procedimento di escussione con eventuale restituzione dell''importo residuo.',      0, 1,  40, 1),
(N'DOCUMENTAZIONE_ESCUSSIONE',        N'ESCUSSIONE', N'Documentazione a supporto escussione (upload)',         NULL,                                                N'Documenti a supporto della procedura di escussione caricati manualmente (es: verbali, atti, corrispondenza).',          0, 0,  50, 1);
GO

-- =============================================
-- Testi PEC predefiniti per i tipi di documento più comuni
-- (sezione 3.5.4 TO BE "Invio PEC dall'Applicazione")
-- I segnaposto {…} sono risolti a runtime dal motore di composizione PEC.
-- I testi qui sotto sono modelli di partenza modificabili dall'amministratore.
-- =============================================

-- ---- CONVALIDA ----
UPDATE [dbo].[RegistroCauzioneTipoDocumento]
SET
    [PecOggetto] = N'Rif. cauzione n. {NumIns}/{AnnoIns} - polizza n. {NPolizza} - Conferma validità',
    [PecCorpo]   = N'Spett.le {DenomFideiussore} - {AgenziaFideiussore},' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'con la presente si comunica che la polizza fideiussoria n. {NPolizza}, ' +
                   N'emessa a favore di {RagioneSociale}, con scadenza {ScadenzaPolizza} ' +
                   N'e importo garantito pari a Euro {ImpTotale}, ' +
                   N'è stata verificata e risulta conforme ai requisiti richiesti.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'In allegato si trasmette la lettera di conferma validità firmata digitalmente.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'Distinti saluti',
    [PecFirma]   = N'{FirmaUfficio}',
    [IsPecObbligatoria] = 1
WHERE [CodTipoDocumento] = N'LETTERA_CONFERMA_VALIDITA'
GO

UPDATE [dbo].[RegistroCauzioneTipoDocumento]
SET
    [PecOggetto] = N'Rif. cauzione n. {NumIns}/{AnnoIns} - polizza n. {NPolizza} - Primo sollecito documentazione',
    [PecCorpo]   = N'Spett.le {DenomFideiussore} - {AgenziaFideiussore},' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'con riferimento alla polizza fideiussoria n. {NPolizza} relativa alla pratica ' +
                   N'n. {NumIns}/{AnnoIns} intestata a {RagioneSociale}, si richiede cortesemente ' +
                   N'di voler trasmettere la documentazione integrativa indicata nella lettera allegata.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'Distinti saluti',
    [PecFirma]   = N'{FirmaUfficio}',
    [IsPecObbligatoria] = 0
WHERE [CodTipoDocumento] = N'SOLLECITO_INFORMALE_VALIDITA'
GO

UPDATE [dbo].[RegistroCauzioneTipoDocumento]
SET
    [PecOggetto] = N'Rif. cauzione n. {NumIns}/{AnnoIns} - polizza n. {NPolizza} - Sollecito FORMALE documentazione - SCADENZA PERENTORIA',
    [PecCorpo]   = N'Spett.le {DenomFideiussore} - {AgenziaFideiussore},' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'in riferimento ai precedenti contatti relativi alla polizza fideiussoria n. {NPolizza}, ' +
                   N'pratica n. {NumIns}/{AnnoIns} intestata a {RagioneSociale}, ' +
                   N'si diffida formalmente a provvedere all''invio della documentazione richiesta ' +
                   N'entro e non oltre 15 giorni dalla data della presente.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'Decorso inutilmente il termine si procederà ai sensi di legge.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'Distinti saluti',
    [PecFirma]   = N'{FirmaUfficio}',
    [IsPecObbligatoria] = 1
WHERE [CodTipoDocumento] = N'SOLLECITO_FORMALE_VALIDITA'
GO

UPDATE [dbo].[RegistroCauzioneTipoDocumento]
SET
    [PecOggetto] = N'Rif. cauzione n. {NumIns}/{AnnoIns} - polizza n. {NPolizza} - Non conformità rilevata',
    [PecCorpo]   = N'Spett.le {DenomFideiussore} - {AgenziaFideiussore},' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'a seguito della verifica della polizza fideiussoria n. {NPolizza}, ' +
                   N'pratica n. {NumIns}/{AnnoIns} intestata a {RagioneSociale}, ' +
                   N'sono state riscontrate le non conformità indicate nella lettera allegata.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'Si richiede di provvedere alle rettifiche indicate entro i termini indicati.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'Distinti saluti',
    [PecFirma]   = N'{FirmaUfficio}',
    [IsPecObbligatoria] = 1
WHERE [CodTipoDocumento] = N'LETTERA_NON_CONFORMITA'
GO

UPDATE [dbo].[RegistroCauzioneTipoDocumento]
SET
    [PecOggetto] = N'Rif. cauzione n. {NumIns}/{AnnoIns} - polizza n. {NPolizza} - Invalidazione polizza',
    [PecCorpo]   = N'Spett.le {DenomFideiussore} - {AgenziaFideiussore},' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'si comunica che la polizza fideiussoria n. {NPolizza}, ' +
                   N'pratica n. {NumIns}/{AnnoIns} intestata a {RagioneSociale}, ' +
                   N'è stata dichiarata non valida per le motivazioni indicate nella lettera allegata.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'Si richiede la sostituzione del documento entro i termini indicati.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'Distinti saluti',
    [PecFirma]   = N'{FirmaUfficio}',
    [IsPecObbligatoria] = 1
WHERE [CodTipoDocumento] = N'LETTERA_INVALIDAZIONE'
GO

-- ---- VARIAZIONI ----
UPDATE [dbo].[RegistroCauzioneTipoDocumento]
SET
    [PecOggetto] = N'Rif. cauzione n. {NumIns}/{AnnoIns} - polizza n. {NPolizza} - Richiesta variazione contrattuale',
    [PecCorpo]   = N'Spett.le {DenomFideiussore} - {AgenziaFideiussore},' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'con riferimento alla polizza fideiussoria n. {NPolizza}, ' +
                   N'pratica n. {NumIns}/{AnnoIns} intestata a {RagioneSociale}, ' +
                   N'si richiede di procedere alla modifica contrattuale indicata nella lettera allegata.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'Distinti saluti',
    [PecFirma]   = N'{FirmaUfficio}',
    [IsPecObbligatoria] = 1
WHERE [CodTipoDocumento] = N'LETTERA_RICHIESTA_VARIAZIONE'
GO

-- ---- PROROGHE ----
UPDATE [dbo].[RegistroCauzioneTipoDocumento]
SET
    [PecOggetto] = N'Rif. cauzione n. {NumIns}/{AnnoIns} - polizza n. {NPolizza} - Comunicazione proroga progetto',
    [PecCorpo]   = N'Spett.le {DenomFideiussore} - {AgenziaFideiussore},' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'si comunica che il progetto relativo alla pratica n. {NumIns}/{AnnoIns} ' +
                   N'intestata a {RagioneSociale} è stato prorogato.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'Si richiede pertanto il rinnovo della polizza fideiussoria n. {NPolizza} ' +
                   N'alle nuove condizioni indicate nella lettera allegata.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'Distinti saluti',
    [PecFirma]   = N'{FirmaUfficio}',
    [IsPecObbligatoria] = 1
WHERE [CodTipoDocumento] = N'COMUNICAZIONE_PROROGA_PROGETTO'
GO

UPDATE [dbo].[RegistroCauzioneTipoDocumento]
SET
    [PecOggetto] = N'Rif. cauzione n. {NumIns}/{AnnoIns} - polizza n. {NPolizza} - Richiesta rinnovo/proroga polizza',
    [PecCorpo]   = N'Spett.le {DenomFideiussore} - {AgenziaFideiussore},' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'si richiede formalmente il rinnovo della polizza fideiussoria n. {NPolizza}, ' +
                   N'in scadenza il {ScadenzaPolizza}, relativa alla pratica n. {NumIns}/{AnnoIns} ' +
                   N'intestata a {RagioneSociale}.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'Le nuove condizioni richieste sono indicate nella lettera allegata.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'Distinti saluti',
    [PecFirma]   = N'{FirmaUfficio}',
    [IsPecObbligatoria] = 1
WHERE [CodTipoDocumento] = N'LETTERA_RICHIESTA_RINNOVO'
GO

-- ---- SVINCOLO ----
UPDATE [dbo].[RegistroCauzioneTipoDocumento]
SET
    [PecOggetto] = N'Rif. cauzione n. {NumIns}/{AnnoIns} - polizza n. {NPolizza} - Svincolo totale autorizzato',
    [PecCorpo]   = N'Spett.le {DenomFideiussore} - {AgenziaFideiussore},' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'con riferimento alla polizza fideiussoria n. {NPolizza}, ' +
                   N'pratica n. {NumIns}/{AnnoIns} intestata a {RagioneSociale}, ' +
                   N'si comunica il nulla osta allo svincolo totale della garanzia, ' +
                   N'per importo complessivo di Euro {ImpTotale}.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'In allegato la lettera di autorizzazione firmata digitalmente.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'Distinti saluti',
    [PecFirma]   = N'{FirmaUfficio}',
    [IsPecObbligatoria] = 1
WHERE [CodTipoDocumento] = N'LETTERA_AUTORIZZAZIONE_SVINCOLO_TOTALE'
GO

UPDATE [dbo].[RegistroCauzioneTipoDocumento]
SET
    [PecOggetto] = N'Rif. cauzione n. {NumIns}/{AnnoIns} - polizza n. {NPolizza} - Svincolo parziale autorizzato',
    [PecCorpo]   = N'Spett.le {DenomFideiussore} - {AgenziaFideiussore},' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'con riferimento alla polizza fideiussoria n. {NPolizza}, ' +
                   N'pratica n. {NumIns}/{AnnoIns} intestata a {RagioneSociale}, ' +
                   N'si comunica il nulla osta allo svincolo parziale della garanzia. ' +
                   N'L''importo da svincolare e le modalità operative sono indicate nella lettera allegata.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'Distinti saluti',
    [PecFirma]   = N'{FirmaUfficio}',
    [IsPecObbligatoria] = 0
WHERE [CodTipoDocumento] = N'LETTERA_AUTORIZZAZIONE_SVINCOLO_PARZIALE'
GO

-- ---- ESCUSSIONE ----
UPDATE [dbo].[RegistroCauzioneTipoDocumento]
SET
    [PecOggetto] = N'Rif. cauzione n. {NumIns}/{AnnoIns} - polizza n. {NPolizza} - Avviso escussione',
    [PecCorpo]   = N'Egr. Sig./Spett.le Soc. {RagioneSociale},' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'con la presente si comunica l''avvio del procedimento di escussione ' +
                   N'della polizza fideiussoria n. {NPolizza}, ' +
                   N'pratica n. {NumIns}/{AnnoIns}.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'I dettagli del procedimento sono indicati nella lettera allegata.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'Distinti saluti',
    [PecFirma]   = N'{FirmaUfficio}',
    [IsPecObbligatoria] = 1
WHERE [CodTipoDocumento] = N'AVVISO_DEBITORE'
GO

UPDATE [dbo].[RegistroCauzioneTipoDocumento]
SET
    [PecOggetto] = N'Rif. cauzione n. {NumIns}/{AnnoIns} - polizza n. {NPolizza} - Avviso escussione al garante',
    [PecCorpo]   = N'Spett.le {DenomFideiussore} - {AgenziaFideiussore},' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'con la presente si comunica l''avvio del procedimento di escussione ' +
                   N'della polizza fideiussoria n. {NPolizza}, ' +
                   N'pratica n. {NumIns}/{AnnoIns} intestata a {RagioneSociale}.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'La lettera formale di escussione seguirà nei termini di legge.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'Distinti saluti',
    [PecFirma]   = N'{FirmaUfficio}',
    [IsPecObbligatoria] = 1
WHERE [CodTipoDocumento] = N'AVVISO_GARANTE'
GO

UPDATE [dbo].[RegistroCauzioneTipoDocumento]
SET
    [PecOggetto] = N'Rif. cauzione n. {NumIns}/{AnnoIns} - polizza n. {NPolizza} - Escussione fideiussione - FORMALE',
    [PecCorpo]   = N'Spett.le {DenomFideiussore} - {AgenziaFideiussore},' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'con la presente si richiede formalmente il pagamento dell''importo escusso ' +
                   N'relativo alla polizza fideiussoria n. {NPolizza}, ' +
                   N'pratica n. {NumIns}/{AnnoIns} intestata a {RagioneSociale}.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'L''importo richiesto, le coordinate di pagamento e le scadenze ' +
                   N'sono indicati nella lettera allegata.' + CHAR(13)+CHAR(10) +
                   CHAR(13)+CHAR(10) +
                   N'Distinti saluti',
    [PecFirma]   = N'{FirmaUfficio}',
    [IsPecObbligatoria] = 1
WHERE [CodTipoDocumento] = N'LETTERA_ESCUSSIONE'
GO

-- =============================================
-- Extended Properties
-- =============================================
EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Lookup dei tipi di documento gestibili nel Fascicolo Digitale della Scheda Cauzione, con riferimento ai template Word (sezione 3.5.1 TO BE "Modelli di Lettera") e ai testi predefiniti per la composizione della PEC (sezione 3.5.4 TO BE). Sostituisce il riferimento alla vecchia tabella [DocTipoDocumento]. L''ID è usato come FK da RegistroCauzioniFascicoloDigitale.IDTipoDocumento.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioneTipoDocumento'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Nome del file template Word da cui viene generato il documento (es: Template_Lettera_Conferma_Validita.docx). NULL se il documento è solo upload manuale (IsGeneratoAutomatico=0).',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioneTipoDocumento',
    @level2type=N'COLUMN', @level2name=N'NomeTemplateFile'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Se 1, il documento è generabile automaticamente dal sistema a partire dal template Word. Se 0, viene caricato manualmente dall''utente (documento esterno).',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioneTipoDocumento',
    @level2type=N'COLUMN', @level2name=N'IsGeneratoAutomatico'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Se 1, il documento è obbligatorio per completare la sezione operativa. Il sistema impedisce la chiusura della sezione senza questo documento in stato RICEVUTO o FIRMATO.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioneTipoDocumento',
    @level2type=N'COLUMN', @level2name=N'IsObbligatorio'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Se 1, il documento deve essere obbligatoriamente trasmesso via PEC (non è sufficiente la sola firma digitale e archiviazione). Usato per i documenti che richiedono prova di trasmissione certificata.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioneTipoDocumento',
    @level2type=N'COLUMN', @level2name=N'IsPecObbligatoria'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Oggetto predefinito della PEC (sezione 3.5.4 TO BE). Supporta segnaposto risolti a runtime: {NumIns}, {AnnoIns}, {NPolizza}, {RagioneSociale}, {DenomFideiussore}, {AgenziaFideiussore}, {ScadenzaPolizza}, {ImpTotale}, {DataOggi}, {NomeUfficio}. NULL = nessun testo predefinito, operatore compila manualmente.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioneTipoDocumento',
    @level2type=N'COLUMN', @level2name=N'PecOggetto'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Corpo predefinito della PEC (testo libero multiriga, sezione 3.5.4 TO BE). Supporta gli stessi segnaposto di PecOggetto. L''applicazione pre-compila la maschera di invio PEC con questo testo; l''operatore può modificarlo prima dell''invio definitivo. NULL = nessun testo predefinito.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioneTipoDocumento',
    @level2type=N'COLUMN', @level2name=N'PecCorpo'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Blocco firma predefinito da accodare al corpo della PEC (sezione 3.5.4 TO BE). Tipicamente contiene nome ufficio, indirizzo, recapiti. Supporta il segnaposto {FirmaUfficio} risolto dalla configurazione di sistema. NULL = nessuna firma predefinita.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioneTipoDocumento',
    @level2type=N'COLUMN', @level2name=N'PecFirma'
GO
