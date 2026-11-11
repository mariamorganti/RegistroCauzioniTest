USE  [DBRegistroCauzioni]
GO

/****** Tabella multi-ciclo della sezione Variazioni - campi estratti da GstCauzioni ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- TABELLA: RegistroCauzioniVariazioni
-- SCOPO: Registra ogni ciclo di variazione di una cauzione. Multi-ciclo perché
--        nel corso del ciclo di vita di una cauzione possono intervenire più
--        richieste di modifica del contratto (es: cambio importo, cambio durata,
--        cambio beneficiario).
--
-- ORIGINE CAMPI: Estratti da [dbo].[GstCauzioni]:
--   ProtRichModificaContratto, DataRichModificaContratto,
--   ProtRicezioneIntegrazione, DataRicezioneIntegrazione,
--   ProtRichiestaValidazione, DataRichiestaValidazione,
--   ProtEsitoValidazione, DataEsitoValidazione, FlagEsitoValidazione.
--
-- CAMPI AGGIUNTI:
--   IDRegistroCauzioni: FK verso la tabella principale.
--   Status: stato della variazione. DEFAULT=0 (NON_AVVIATA).
--     Valori da RegistroCauzioniStatus con CodSezione='VARIAZIONI'. NO FK applicata.
--   NumCiclo: progressivo della variazione.
--   TipoVariazione: descrive il tipo di modifica richiesta (importo, scadenza, dati, altro).
--   DataScadenzaAttesa: soglia per transizione automatica in IN_RITARDO (default +15gg).
--   DescrizioneVariazione: dettaglio narrativo della modifica richiesta.
--   ImportoNuovo: nuovo importo garantito (se la variazione riguarda l'importo).
--   ScadenzaNuova: nuova scadenza della polizza (se la variazione riguarda la durata).
-- =============================================

CREATE TABLE [dbo].[RegistroCauzioniVariazioni](
    [ID]                            [int]           IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
    [IDRegistroCauzioni]            [int]           NOT NULL,  -- FK verso RegistroCauzioni.ID
    [NumCiclo]                      [smallint]      NOT NULL CONSTRAINT [DF_RCVariazioni_NumCiclo] DEFAULT (1),
    [Status]                        [smallint]      NOT NULL CONSTRAINT [DF_RCVariazioni_Status] DEFAULT (0),
    -- Valori da RegistroCauzioniStatus dove CodSezione='VARIAZIONI'. NO FK applicata.
    -- 0=NON_AVVIATA, 210=RICHIESTA_INVIATA, 220=IN_RITARDO, 230=INTEGRAZIONE_RIC, 240=COMPLETATA

    -- ---- Tipologia e descrizione della variazione ----
    [TipoVariazione]                [nvarchar](50)  NULL,  -- es: IMPORTO, SCADENZA, DATI_FIDEIUSSORE, ALTRO
    [DescrizioneVariazione]         [nvarchar](1000) NULL,

    -- ---- Nuovi valori richiesti (se applicabili) ----
    [ImportoNuovo]                  [decimal](18,2) NULL,  -- nuovo ImpTotale se variazione importo
    [ScadenzaNuova]                 [datetime2](7)  NULL,  -- nuova ScadenzaPolizza se variazione durata

    -- ---- Gestione temporale ----
    [DataAvvio]                     [datetime2](7)  NULL,
    [DataScadenzaAttesa]            [datetime2](7)  NULL,  -- soglia IN_RITARDO (default: DataAvvio + 15 giorni)
    [DataCambioStatus]              [datetime2](7)  NULL,

    -- ---- Richiesta modifica contratto (già in GstCauzioni) ----
    [ProtRichModificaContratto]     [nvarchar](30)  NULL,
    [DataRichModificaContratto]     [datetime2](7)  NULL,

    -- ---- Ricezione documentazione integrativa ----
    [ProtRicezioneIntegrazione]     [nvarchar](30)  NULL,
    [DataRicezioneIntegrazione]     [datetime2](7)  NULL,

    -- ---- Richiesta e esito validazione formale ----
    [ProtRichiestaValidazione]      [nvarchar](30)  NULL,
    [DataRichiestaValidazione]      [datetime2](7)  NULL,
    [ProtEsitoValidazione]          [nvarchar](30)  NULL,
    [DataEsitoValidazione]          [datetime2](7)  NULL,
    [FlagEsitoValidazione]          [bit]           NOT NULL CONSTRAINT [DF_RCVariazioni_FlagEsitoValidazione] DEFAULT (0),

    -- ---- Note e audit ----
    [Note]                          [nvarchar](1000) NULL,
    [DataInserimento]               [datetime2](7)  NOT NULL CONSTRAINT [DF_RCVariazioni_DataInserimento] DEFAULT (SYSDATETIME()),
    [DataModifica]                  [datetime2](7)  NOT NULL CONSTRAINT [DF_RCVariazioni_DataModifica] DEFAULT (SYSDATETIME()),
    [IDOperatore]                   [int]           NOT NULL,

 CONSTRAINT [PK_RegistroCauzioniVariazioni] PRIMARY KEY CLUSTERED
(
    [ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
       ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80,
       OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [UQ_RCVariazioni_IDRegistroCauzioni_NumCiclo] UNIQUE NONCLUSTERED
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
ALTER TABLE [dbo].[RegistroCauzioniVariazioni] WITH CHECK ADD CONSTRAINT [FK_RCVariazioni_RegistroCauzioni]
    FOREIGN KEY([IDRegistroCauzioni]) REFERENCES [dbo].[RegistroCauzioni] ([ID])
    ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[RegistroCauzioniVariazioni] CHECK CONSTRAINT [FK_RCVariazioni_RegistroCauzioni]
GO

-- =============================================
-- Indici
-- =============================================
CREATE NONCLUSTERED INDEX [IX_RCVariazioni_Status]
    ON [dbo].[RegistroCauzioniVariazioni] ([Status] ASC)
    INCLUDE ([IDRegistroCauzioni],[NumCiclo],[DataScadenzaAttesa])
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, FILLFACTOR = 80,
          OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

-- =============================================
-- Extended Properties
-- =============================================
EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Tabella multi-ciclo della sezione Variazioni. Ogni record rappresenta un ciclo di variazione del contratto per una cauzione. Campi estratti da [dbo].[GstCauzioni]. Status=0=NON_AVVIATA (default). NON ha FK verso RegistroCauzioniStatus: validazione applicativa.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniVariazioni'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Stato del ciclo di variazione. Valori in RegistroCauzioniStatus con CodSezione=''VARIAZIONI''. DEFAULT=0=NON_AVVIATA. NON ha FK: validazione applicativa.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniVariazioni',
    @level2type=N'COLUMN', @level2name=N'Status'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Data entro cui si attende risposta dal fideiussore. Se superata, il job notturno porta lo stato a IN_RITARDO. Default: DataAvvio + 15 giorni.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniVariazioni',
    @level2type=N'COLUMN', @level2name=N'DataScadenzaAttesa'
GO
