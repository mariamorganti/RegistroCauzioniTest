USE [DBRegistroCauzioni]
GO


/****** Tabella principale del Registro Cauzioni - refactoring di GstCauzioni ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- TABELLA: RegistroCauzioni
-- SCOPO: Tabella principale del registro cauzioni. Refactoring di [dbo].[GstCauzioni].
--
-- MODIFICHE RISPETTO A GstCauzioni:
--   RIMOSSE:
--     - FK su (NDomanda, IDTipoDomanda) verso [Domanda]: rimossa perché la domanda
--       collegata può essere rettificata (sezione 3.4.4 TO BE) e il vincolo impediva
--       la modifica. La relazione è mantenuta come riferimento informale applicativo.
--     - Campi obsoleti relativi alle quote di finanziamento EU/nazionali non più
--       gestiti dal sistema: ImpFEOGA, ImpQuotaStato, ImpQuotaRegione, ImpCapitale,
--       ImpInteressiSpese, ImpIntSpeseFEOGA.
--     - DataConcServTec: campo non più pertinente nel nuovo flusso TO BE.
--     - Tutti i campi di Convalida (spostati in RegistroCauzioniConvalida).
--     - Tutti i campi di Variazioni (spostati in RegistroCauzioniVariazioni).
--     - Campi di Proroga (ProtComunicazioneProroga, DataComunicazioneProroga,
--       ScadenzaUltimoRinnovo, DataProrogaProgetto) spostati in RegistroCauzioniProroghe.
--     - CHECK CK_GstCauzioni_escussrich e CK_GstCauzioni_escusssvinc: la logica
--       di validazione è spostata a livello applicativo per consentire stati intermedi
--       senza violare i constraint durante operazioni parziali.
--
--   AGGIUNTE:
--     - StatusGenerale (smallint DEFAULT 0): stato del ciclo di vita principale (5.1).
--       Valori da RegistroCauzioniStatus dove CodSezione='GENERALE'. NO FK applicata.
--     - StatusEscussione (smallint DEFAULT 0): stato specifico della sezione Escussione.
--       Mantenuto nel record principale perché l'escussione è mono-ciclo per cauzione.
--     - FlagEntePublico (bit DEFAULT 0): distingue fideiussori che sono enti pubblici,
--       con iter documentale differente.
--     - ProtPECOriginale (nvarchar(100)): protocollo PEC di trasmissione dell'originale
--       (nuovo flusso digitale sezione 3.4.1).
--     - PECAgenziaFideiussore (nvarchar(254)): indirizzo PEC dell'agenzia specifica
--       (può differire dalla PEC della casa madre in CodFideiussore).
--     - FirmatarioGaranzia (nvarchar(200)): nome del firmatario della polizza/fideiussione.
--     - DataInserimento (datetime2(7)): data/ora di creazione del record (separata da
--       DataModifica che registra solo l'ultima modifica).
--     - IDCreatore (int): IDUtente che ha creato il record (IDOperatore registra solo
--       l'ultimo modificatore).
--
--   CONVERSIONI DI TIPO:
--     - datetime  → datetime2(7): maggiore precisione, range esteso, standard SQL.
--     - money      → decimal(18,2): evita problemi di arrotondamento in operazioni
--       aritmetiche e garantisce precisione su importi.
--     - varchar   → nvarchar: supporto Unicode per denominazioni e note in lingue diverse.
--
--   MANTENUTI (mono-ciclo, restano nel record principale):
--     - Tutti i campi di Escussione: l'escussione avviene una sola volta per cauzione.
--     - SumImportoSvincolato: totale running degli svincoli parziali (aggiornato da trigger
--       o dal layer applicativo ad ogni svincolo parziale in RegistroCauzioniSvincolo).
-- =============================================

CREATE TABLE [dbo].[RegistroCauzioni](
    -- ---- Chiavi e identificativi ----
    [ID]                            [int]           IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
    [NumIns]                        [int]           NOT NULL,  -- numero progressivo nell'anno
    [AnnoIns]                       [smallint]      NOT NULL,  -- anno di inserimento (range: 1753-9999)
    [DataIdentificativo]            [datetime2](7)  NOT NULL CONSTRAINT [DF_RegistroCauzioni_DataIdentificativo] DEFAULT (SYSDATETIME()),

    -- ---- Collegamento alla domanda (senza FK, rettificabile) ----
    [IDTipoDomanda]                 [int]           NOT NULL,  -- codice tipo procedimento (CodTipoDomanda)
    [NDomanda]                      [nvarchar](50)  NOT NULL,  -- codice domanda di aiuto
    [IDTipoDomandaModulo]           [int]           NULL,      -- tipo domanda del modulo se diverso
    [NDomandaModulo]                [nvarchar](50)  NULL,      -- codice domanda del modulo

    -- ---- Dati della polizza/fideiussione ----
    [NPolizza]                      [nvarchar](50)  NULL,
    [DataPolizza]                   [datetime2](7)  NULL,
    [ScadenzaPolizza]               [datetime2](7)  NULL,
    [ScadenzaProgetto]              [datetime2](7)  NULL,

    -- ---- Importi ----
    [ImpTotale]                     [decimal](18,2) NOT NULL CONSTRAINT [DF_RegistroCauzioni_ImpTotale] DEFAULT (0),
    [SumImportoSvincolato]          [decimal](18,2) NOT NULL CONSTRAINT [DF_RegistroCauzioni_SumImportoSvincolato] DEFAULT (0),

    -- ---- Dati fideiussore ----
    [IDFideiussore]                 [int]           NOT NULL,  -- FK verso CodFideiussore
    [AgenziaFideiussore]            [nvarchar](150) NULL,
    [CFAgenziaFideiussore]          [nvarchar](16)  NULL,
    [IndirizzoAgenziaFideiussore]   [nvarchar](150) NULL,
    [PIVAAgenziaFideiussore]        [nvarchar](11)  NULL,
    [PECAgenziaFideiussore]         [nvarchar](254) NULL,  -- PEC specifica dell'agenzia
    [FirmatarioGaranzia]            [nvarchar](200) NULL,  -- nome firmatario della polizza
    [FlagEntePublico]               [bit]           NOT NULL CONSTRAINT [DF_RegistroCauzioni_FlagEntePublico] DEFAULT (0),

    -- ---- Tipo cauzione ----
    [IDTipoCauzione]                [int]           NOT NULL,  -- FK verso CodTipoCauzione

    -- ---- Ricezione originale (nuovi campi flusso digitale) ----
    [ProtPECOriginale]              [nvarchar](100) NULL,  -- protocollo PEC invio/ricezione originale
    [DataRicezioneOriginale]        [datetime2](7)  NULL,
    [ProtRicezioneOriginale]        [nvarchar](30)  NULL,  -- protocollo cartaceo/interno ricezione

    -- ---- Dati escussione (mono-ciclo: resta nel record principale) ----
    [StatusEscussione]              [smallint]      NOT NULL CONSTRAINT [DF_RegistroCauzioni_StatusEscussione] DEFAULT (0),
    [DataRicezioneAvvisoDebitore]   [datetime2](7)  NULL,
    [DataRicezioneAvvisoGarante]    [datetime2](7)  NULL,
    [ProtComunicazioneEscussione]   [nvarchar](30)  NULL,
    [DataComunicazioneEscussione]   [datetime2](7)  NULL,
    [ProtLetteraEscussione]         [nvarchar](30)  NULL,
    [DataLetteraEscussione]         [datetime2](7)  NULL,
    [ProtLetteraRestituzione]       [nvarchar](30)  NULL,
    [DataLetteraRestituzione]       [datetime2](7)  NULL,
    [ImpRichiesto]                  [decimal](18,2) NOT NULL CONSTRAINT [DF_RegistroCauzioni_ImpRichiesto] DEFAULT (0),
    [ImpIncamerato]                 [decimal](18,2) NOT NULL CONSTRAINT [DF_RegistroCauzioni_ImpIncamerato] DEFAULT (0),

    -- ---- Stato generale della cauzione (ciclo di vita 5.1) ----
    [StatusGenerale]                [smallint]      NOT NULL CONSTRAINT [DF_RegistroCauzioni_StatusGenerale] DEFAULT (0),
    -- Valori da RegistroCauzioniStatus dove CodSezione='GENERALE'. NO FK applicata.
    -- 0=INIZIALE, 10=DA_RICEVERE, 20=IN_ESSERE, 30=IN_SCADENZA, 40=SCADUTA, 50=IN_SVINCOLO, 60=CHIUSA

    [FlagInEssere]                  [bit]           NOT NULL CONSTRAINT [DF_RegistroCauzioni_FlagInEssere] DEFAULT (0),
    [ApprovatoCheckList]            [bit]           NOT NULL CONSTRAINT [DF_RegistroCauzioni_ApprovatoCheckList] DEFAULT (0),

    -- ---- Note e campi gestionali ----
    [Note]                          [nvarchar](1000) NULL,
    [CupArtea]                      [nvarchar](255) NULL,

    -- ---- Audit ----
    [DataInserimento]               [datetime2](7)  NOT NULL CONSTRAINT [DF_RegistroCauzioni_DataInserimento] DEFAULT (SYSDATETIME()),
    [IDCreatore]                    [int]           NOT NULL,
    [DataModifica]                  [datetime2](7)  NOT NULL CONSTRAINT [DF_RegistroCauzioni_DataModifica] DEFAULT (SYSDATETIME()),
    [IDOperatore]                   [int]           NOT NULL,

 CONSTRAINT [PK_RegistroCauzioni] PRIMARY KEY CLUSTERED
(
    [ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
       ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70,
       OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [IX_RegistroCauzioni_LogicKey] UNIQUE NONCLUSTERED
(
    [NumIns] ASC,
    [AnnoIns] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
       ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 70,
       OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- =============================================
-- CHECK Constraints
-- =============================================

ALTER TABLE [dbo].[RegistroCauzioni] WITH NOCHECK ADD CONSTRAINT [CK_RegistroCauzioni_AnnoIns]
    CHECK (([AnnoIns] >= 1753 AND [AnnoIns] <= 9999))
GO
ALTER TABLE [dbo].[RegistroCauzioni] CHECK CONSTRAINT [CK_RegistroCauzioni_AnnoIns]
GO

-- ImpIncamerato <= ImpRichiesto (invariante finanziaria escussione)
ALTER TABLE [dbo].[RegistroCauzioni] WITH NOCHECK ADD CONSTRAINT [CK_RegistroCauzioni_ImpIncamerato]
    CHECK (([ImpIncamerato] <= [ImpRichiesto]))
GO
ALTER TABLE [dbo].[RegistroCauzioni] CHECK CONSTRAINT [CK_RegistroCauzioni_ImpIncamerato]
GO

-- =============================================
-- FK verso tabelle di codifica (mantenute da GstCauzioni)
-- =============================================

ALTER TABLE [dbo].[RegistroCauzioni] WITH NOCHECK ADD CONSTRAINT [FK_RegistroCauzioni_CodFideiussore]
    FOREIGN KEY([IDFideiussore]) REFERENCES [dbo].[CodFideiussore] ([IDFideiussore])
GO
ALTER TABLE [dbo].[RegistroCauzioni] CHECK CONSTRAINT [FK_RegistroCauzioni_CodFideiussore]
GO

--ALTER TABLE [dbo].[RegistroCauzioni] WITH NOCHECK ADD CONSTRAINT [FK_RegistroCauzioni_IDTipoCauzione]
--    FOREIGN KEY([IDTipoCauzione]) REFERENCES [dbo].IDTipoCauzione ([IDTipoCauzione])
--GO
--ALTER TABLE [dbo].[RegistroCauzioni] CHECK CONSTRAINT [FK_RegistroCauzioni_IDTipoCauzione]
--GO

-- NOTA: NON viene creata FK verso [dbo].[Domanda] su (NDomanda, IDTipoDomanda).
-- Motivazione: la sezione 3.4.4 TO BE prevede la possibilità di rettificare la domanda
-- collegata. Un FK constraint impedirebbe la modifica dei campi NDomanda/IDTipoDomanda
-- se il record non esiste in Domanda, o impedirebbe la cancellazione della domanda.
-- La correttezza del riferimento è garantita a livello applicativo.

-- =============================================
-- Indici aggiuntivi per ottimizzazione query frequenti
-- =============================================

CREATE NONCLUSTERED INDEX [IX_RegistroCauzioni_NDomanda]
    ON [dbo].[RegistroCauzioni] ([NDomanda] ASC, [IDTipoDomanda] ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, FILLFACTOR = 80,
          OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_RegistroCauzioni_StatusGenerale]
    ON [dbo].[RegistroCauzioni] ([StatusGenerale] ASC)
    INCLUDE ([NumIns],[AnnoIns],[IDFideiussore],[ScadenzaPolizza],[ImpTotale])
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, FILLFACTOR = 80,
          OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_RegistroCauzioni_ScadenzaPolizza]
    ON [dbo].[RegistroCauzioni] ([ScadenzaPolizza] ASC)
    INCLUDE ([StatusGenerale],[NumIns],[AnnoIns])
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, FILLFACTOR = 80,
          OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

-- =============================================
-- Extended Properties
-- =============================================
EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Tabella principale del Registro Cauzioni. Refactoring di [dbo].[GstCauzioni]: rimossa FK su Domanda (rettificabile per TO BE 3.4.4), rimossi campi obsoleti quote EU/nazionali, rimossi campi multi-ciclo (Convalida→RegistroCauzioniConvalida, Variazioni→RegistroCauzioniVariazioni, Proroghe→RegistroCauzioniProroghe). Rimangono i campi mono-ciclo dell''Escussione. Tipi aggiornati: datetime→datetime2(7), money→decimal(18,2), varchar→nvarchar.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioni'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Chiave tecnica auto-incrementale. Sostituisce NIdentificativoInterno di GstCauzioni.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioni',
    @level2type=N'COLUMN', @level2name=N'ID'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Codice identificativo della domanda di aiuto. NON ha FK verso [Domanda]: la domanda collegata può essere rettificata (TO BE 3.4.4). Validazione applicativa.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioni',
    @level2type=N'COLUMN', @level2name=N'NDomanda'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Stato del ciclo di vita principale della cauzione (sezione 5.1). Valori in RegistroCauzioniStatus con CodSezione=''GENERALE''. 0=INIZIALE (default). NON ha FK verso RegistroCauzioniStatus: validazione applicativa.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioni',
    @level2type=N'COLUMN', @level2name=N'StatusGenerale'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Stato della procedura di escussione (sezione 5.2.5). Rimane nel record principale perché l''escussione è mono-ciclo per cauzione. 0=NON_AVVIATA (default). Valori in RegistroCauzioniStatus con CodSezione=''ESCUSSIONE''.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioni',
    @level2type=N'COLUMN', @level2name=N'StatusEscussione'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Totale importo progressivamente svincolato (somma di tutti i record in RegistroCauzioniSvincolo con EsitoPositivo=1). Aggiornato dal layer applicativo ad ogni svincolo parziale completato.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioni',
    @level2type=N'COLUMN', @level2name=N'SumImportoSvincolato'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Indirizzo PEC specifico dell''agenzia fideiussore (può differire dalla PEC della casa madre registrata in CodFideiussore).',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioni',
    @level2type=N'COLUMN', @level2name=N'PECAgenziaFideiussore'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Protocollo PEC di trasmissione/ricezione dell''originale della polizza (nuovo flusso digitale sezione 3.4.1).',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioni',
    @level2type=N'COLUMN', @level2name=N'ProtPECOriginale'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'IDUtente che ha creato il record per la prima volta. IDOperatore registra solo l''ultimo modificatore.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioni',
    @level2type=N'COLUMN', @level2name=N'IDCreatore'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Data e ora di prima creazione del record. Separata da DataModifica che traccia solo le successive modifiche.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioni',
    @level2type=N'COLUMN', @level2name=N'DataInserimento'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Data di ultima modifica del record.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioni',
    @level2type=N'COLUMN', @level2name=N'DataModifica'
GO
