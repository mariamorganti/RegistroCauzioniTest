USE  [DBRegistroCauzioni]
GO

/****** Tabella multi-ciclo della sezione Convalida - campi estratti da GstCauzioni ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- TABELLA: RegistroCauzioniConvalida
-- SCOPO: Registra ogni ciclo di convalida di una cauzione. Multi-ciclo perché
--        una cauzione può richiedere più convalide nel suo ciclo di vita
--        (es: convalida iniziale + riconvalida dopo invalidazione + riconvalida
--        dopo variazione sostanziale del contratto).
--
-- ORIGINE CAMPI: La maggior parte dei campi proviene da [dbo].[GstCauzioni]
--        dove erano mescolati in un unico record insieme ai dati di variazioni,
--        proroghe ed escussione. La separazione in questa tabella consente di
--        storicizzare ogni ciclo di convalida mantenendo traccia completa.
--
-- CAMPI RIMOSSI DA GstCauzioni:
--   ProtRicezioneOriginale, DataRicezioneOriginale → mantenuti in RegistroCauzioni
--     (la ricezione dell'originale è mono-evento per cauzione, non per convalida)
--   I campi relativi allo svincolo e all'escussione rimangono nelle rispettive tabelle.
--
-- CAMPI AGGIUNTI:
--   IDRegistroCauzioni: FK verso la tabella principale.
--   Status: stato della convalida (valori da RegistroCauzioniStatus con CodSezione='CONVALIDA').
--     DEFAULT=0 (NON_AVVIATA). NON ha FK verso RegistroCauzioniStatus.
--   NumCiclo: numero progressivo del ciclo di convalida per la cauzione (1=prima convalida).
--   DataAvvio: data di avvio formale del ciclo di convalida.
--   DataScadenzaAttesa: data entro cui si attende risposta (per calcolo IN_RITARDO).
--   MotivoRiapertura: motivo per cui si avvia un ciclo successivo al primo.
--   DataCambioStatus: data dell'ultimo cambio di stato (per calcolo scadenze).
-- =============================================

CREATE TABLE [dbo].[RegistroCauzioniConvalida](
    [ID]                        [int]           IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
    [IDRegistroCauzioni]        [int]           NOT NULL,  -- FK verso RegistroCauzioni.ID
    [NumCiclo]                  [smallint]      NOT NULL CONSTRAINT [DF_RCConvalida_NumCiclo] DEFAULT (1),
    [Status]                    [smallint]      NOT NULL CONSTRAINT [DF_RCConvalida_Status] DEFAULT (0),
    -- Valori da RegistroCauzioniStatus dove CodSezione='CONVALIDA'. NO FK applicata.
    -- 0=NON_AVVIATA, 110=IN_ATTESA_ORIGINALE, 120=ORIGINALE_RICEVUTO, 130=IN_ATTESA_ESITO,
    -- 140=NON_CONFORME, 150=IN_ATTESA_INTEGRAZ, 160=CONFORME, 170=IN_RITARDO,
    -- 180=INVALIDATA, 190=COMPLETATA

    -- ---- Dati temporali del ciclo ----
    [DataAvvio]                 [datetime2](7)  NULL,
    [DataScadenzaAttesa]        [datetime2](7)  NULL,  -- soglia per transizione in IN_RITARDO (default +30gg da invio PEC)
    [DataCambioStatus]          [datetime2](7)  NULL,
    [MotivoRiapertura]          [nvarchar](500) NULL,  -- valorizzato se NumCiclo > 1

    -- ---- Conformità ----
    [ProtRepertorio]            [nvarchar](30)  NULL,  -- repertorio di registrazione
    [DataConformita]            [datetime2](7)  NULL,  -- data verifica conformità
    [EsitoConformita]           [bit]           NOT NULL CONSTRAINT [DF_RCConvalida_EsitoConformita] DEFAULT (0),  -- 1=conforme
    [DataNonConformita]         [datetime2](7)  NULL,
    [FlagControlloScadenza]     [bit]           NOT NULL CONSTRAINT [DF_RCConvalida_FlagControlloScadenza] DEFAULT (0),
    [FlagControlloImporto]      [bit]           NOT NULL CONSTRAINT [DF_RCConvalida_FlagControlloImporto] DEFAULT (0),
    [CauValida]                 [bit]           NOT NULL CONSTRAINT [DF_RCConvalida_CauValida] DEFAULT (0),  -- 1 = polizza validata

    -- ---- Lettera di validità ----
    [ProtLetteraValidita]       [nvarchar](30)  NULL,
    [DataLetteraValidita]       [datetime2](7)  NULL,

    -- ---- Conferma validità dopo sollecito ----
    [ProtConfermaValidita]      [nvarchar](30)  NULL,
    [DataConfermaValidita]      [datetime2](7)  NULL,
    [NumeroSolleciti]           [smallint]      NOT NULL CONSTRAINT [DF_RCConvalida_NumeroSolleciti] DEFAULT (0),
    [IdEnte]                    [smallint]      NULL,  -- ente responsabile della convalida

    -- ---- Reso e autorizzazione ----
    [ProtResoAutoriz]           [nvarchar](30)  NULL,
    [DataResoAutoriz]           [datetime2](7)  NULL,

    -- ---- Sollecito validità ----
    [ProtSollecitoValidita]     [nvarchar](30)  NULL,
    [DataSollecitoValidita]     [datetime2](7)  NULL,

    -- ---- Invalidazione ----
    [FlagInvalidazione]         [bit]           NOT NULL CONSTRAINT [DF_RCConvalida_FlagInvalidazione] DEFAULT (0),
    [MotivoInvalidazione]       [nvarchar](255) NULL,

    -- ---- Custodia originale ----
    [DataConsegnaCustodia]      [datetime2](7)  NULL,
    [DataRitiroCustodia]        [datetime2](7)  NULL,

    -- ---- Integrazione documentale ----
    [ProtRicezioneIntegrazione] [nvarchar](30)  NULL,
    [DataRicezioneIntegrazione] [datetime2](7)  NULL,

    -- ---- Richiesta e esito validazione formale ----
    [ProtRichiestaValidazione]  [nvarchar](30)  NULL,
    [DataRichiestaValidazione]  [datetime2](7)  NULL,
    [ProtEsitoValidazione]      [nvarchar](30)  NULL,
    [DataEsitoValidazione]      [datetime2](7)  NULL,
    [FlagEsitoValidazione]      [bit]           NOT NULL CONSTRAINT [DF_RCConvalida_FlagEsitoValidazione] DEFAULT (0),

    -- ---- Note e audit ----
    [Note]                      [nvarchar](1000) NULL,
    [DataInserimento]           [datetime2](7)  NOT NULL CONSTRAINT [DF_RCConvalida_DataInserimento] DEFAULT (SYSDATETIME()),
    [DataModifica]              [datetime2](7)  NOT NULL CONSTRAINT [DF_RCConvalida_DataModifica] DEFAULT (SYSDATETIME()),
    [IDOperatore]               [int]           NOT NULL,

 CONSTRAINT [PK_RegistroCauzioniConvalida] PRIMARY KEY CLUSTERED
(
    [ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
       ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80,
       OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [UQ_RCConvalida_IDRegistroCauzioni_NumCiclo] UNIQUE NONCLUSTERED
(
    [IDRegistroCauzioni] ASC,
    [NumCiclo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
       ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- =============================================
-- FK verso RegistroCauzioni
-- =============================================
ALTER TABLE [dbo].[RegistroCauzioniConvalida] WITH CHECK ADD CONSTRAINT [FK_RCConvalida_RegistroCauzioni]
    FOREIGN KEY([IDRegistroCauzioni]) REFERENCES [dbo].[RegistroCauzioni] ([ID])
    ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[RegistroCauzioniConvalida] CHECK CONSTRAINT [FK_RCConvalida_RegistroCauzioni]
GO

-- =============================================
-- Indici
-- =============================================
CREATE NONCLUSTERED INDEX [IX_RCConvalida_Status]
    ON [dbo].[RegistroCauzioniConvalida] ([Status] ASC)
    INCLUDE ([IDRegistroCauzioni],[NumCiclo],[DataScadenzaAttesa])
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, FILLFACTOR = 80,
          OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

-- =============================================
-- Extended Properties
-- =============================================
EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Tabella multi-ciclo della sezione Convalida. Ogni record rappresenta un ciclo di convalida per una cauzione. Campi estratti da [dbo].[GstCauzioni] dove erano mescolati con dati di altre sezioni. Status=0=NON_AVVIATA (default). NON ha FK verso RegistroCauzioniStatus: validazione applicativa.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniConvalida'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Stato del ciclo di convalida. Valori in RegistroCauzioniStatus con CodSezione=''CONVALIDA''. DEFAULT=0=NON_AVVIATA. NON ha FK: validazione applicativa.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniConvalida',
    @level2type=N'COLUMN', @level2name=N'Status'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Data entro cui si attende risposta dal fideiussore. Se superata senza risposta, il job notturno porta lo stato a IN_RITARDO. Default: DataAvvio + 30 giorni.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniConvalida',
    @level2type=N'COLUMN', @level2name=N'DataScadenzaAttesa'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Progressivo del ciclo di convalida per la cauzione. 1=prima convalida, 2+=riconvalida dopo invalidazione o variazione sostanziale.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniConvalida',
    @level2type=N'COLUMN', @level2name=N'NumCiclo'
GO
