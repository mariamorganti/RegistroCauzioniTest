USE  [DBRegistroCauzioni]
GO
/****** Tabella multi-ciclo della sezione Svincolo - nuova tabella TO BE ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- TABELLA: RegistroCauzioniSvincolo
-- SCOPO: Registra ogni operazione di svincolo (totale o parziale) di una cauzione.
--        Multi-ciclo perché una cauzione può subire più svincoli parziali successivi
--        prima di raggiungere il svincolo totale.
--
-- ORIGINE CAMPI: Nuova tabella non esistente in GstCauzioni. In GstCauzioni il
--        campo SumImportoSvincolato era un totale cumulativo senza storico delle
--        singole operazioni. Questa tabella introduce la storicizzazione completa
--        di ogni operazione di svincolo.
--
-- RELAZIONE CON RegistroCauzioni:
--   - SumImportoSvincolato in RegistroCauzioni viene aggiornato dal layer applicativo
--     sommando gli ImportoSvincolato di tutti i record in questa tabella con
--     Status=COMPLETATO per lo stesso IDRegistroCauzioni.
--   - Quando SumImportoSvincolato raggiunge ImpTotale, StatusGenerale→CHIUSA.
-- =============================================

CREATE TABLE [dbo].[RegistroCauzioniSvincolo](
    [ID]                            [int]           IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
    [IDRegistroCauzioni]            [int]           NOT NULL,  -- FK verso RegistroCauzioni.ID
    [NumCiclo]                      [smallint]      NOT NULL CONSTRAINT [DF_RCSvincolo_NumCiclo] DEFAULT (1),
    [Status]                        [smallint]      NOT NULL CONSTRAINT [DF_RCSvincolo_Status] DEFAULT (0),
    -- Valori da RegistroCauzioniStatus dove CodSezione='SVINCOLO'. NO FK applicata.
    -- 0=NON_AVVIATO, 410=AUTORIZZATO, 420=COMUNICAZIONE_INVIATA, 430=PARZIALE, 440=COMPLETATO

    -- ---- Tipologia e importi ----
    [TipoSvincolo]                  [nvarchar](20)  NOT NULL CONSTRAINT [DF_RCSvincolo_TipoSvincolo] DEFAULT (N'TOTALE'),
    -- TOTALE o PARZIALE
    [ImportoSvincolato]             [decimal](18,2) NOT NULL CONSTRAINT [DF_RCSvincolo_ImportoSvincolato] DEFAULT (0),
    -- Importo svincolato in questa operazione specifica

    -- ---- Autorizzazione interna ----
    [DataAutorizzazione]            [datetime2](7)  NULL,
    [IDAutorizzatore]               [int]           NULL,  -- IDUtente che ha autorizzato lo svincolo
    [MotivoSvincolo]                [nvarchar](500) NULL,

    -- ---- Comunicazione al fideiussore ----
    [ProtComunicazioneSvincolo]     [nvarchar](30)  NULL,
    [DataComunicazioneSvincolo]     [datetime2](7)  NULL,
    [ProtResoAutoriz]               [nvarchar](30)  NULL,  -- da RegistroCauzioniConvalida: protocollo reso e autorizzazione
    [DataResoAutoriz]               [datetime2](7)  NULL,

    -- ---- Conferma dal fideiussore ----
    [DataConfermaFideiussore]       [datetime2](7)  NULL,
    [ProtConfermaFideiussore]       [nvarchar](30)  NULL,

    -- ---- Gestione temporale ----
    [DataAvvio]                     [datetime2](7)  NULL,
    [DataCambioStatus]              [datetime2](7)  NULL,

    -- ---- Note e audit ----
    [Note]                          [nvarchar](1000) NULL,
    [DataInserimento]               [datetime2](7)  NOT NULL CONSTRAINT [DF_RCSvincolo_DataInserimento] DEFAULT (SYSDATETIME()),
    [DataModifica]                  [datetime2](7)  NOT NULL CONSTRAINT [DF_RCSvincolo_DataModifica] DEFAULT (SYSDATETIME()),
    [IDOperatore]                   [int]           NOT NULL,

 CONSTRAINT [PK_RegistroCauzioniSvincolo] PRIMARY KEY CLUSTERED
(
    [ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
       ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80,
       OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [UQ_RCSvincolo_IDRegistroCauzioni_NumCiclo] UNIQUE NONCLUSTERED
(
    [IDRegistroCauzioni] ASC,
    [NumCiclo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
       ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- =============================================
-- CHECK Constraints
-- =============================================
ALTER TABLE [dbo].[RegistroCauzioniSvincolo] WITH NOCHECK ADD CONSTRAINT [CK_RCSvincolo_TipoSvincolo]
    CHECK ([TipoSvincolo] IN (N'TOTALE', N'PARZIALE'))
GO
ALTER TABLE [dbo].[RegistroCauzioniSvincolo] CHECK CONSTRAINT [CK_RCSvincolo_TipoSvincolo]
GO

ALTER TABLE [dbo].[RegistroCauzioniSvincolo] WITH NOCHECK ADD CONSTRAINT [CK_RCSvincolo_ImportoPositivo]
    CHECK ([ImportoSvincolato] >= 0)
GO
ALTER TABLE [dbo].[RegistroCauzioniSvincolo] CHECK CONSTRAINT [CK_RCSvincolo_ImportoPositivo]
GO

-- =============================================
-- FK verso RegistroCauzioni
-- =============================================
ALTER TABLE [dbo].[RegistroCauzioniSvincolo] WITH CHECK ADD CONSTRAINT [FK_RCSvincolo_RegistroCauzioni]
    FOREIGN KEY([IDRegistroCauzioni]) REFERENCES [dbo].[RegistroCauzioni] ([ID])
    ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[RegistroCauzioniSvincolo] CHECK CONSTRAINT [FK_RCSvincolo_RegistroCauzioni]
GO

-- =============================================
-- Indici
-- =============================================
CREATE NONCLUSTERED INDEX [IX_RCSvincolo_Status]
    ON [dbo].[RegistroCauzioniSvincolo] ([Status] ASC)
    INCLUDE ([IDRegistroCauzioni],[NumCiclo],[ImportoSvincolato])
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, FILLFACTOR = 80,
          OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

-- =============================================
-- Extended Properties
-- =============================================
EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Tabella multi-ciclo della sezione Svincolo. Ogni record rappresenta una singola operazione di svincolo (parziale o totale) di una cauzione. Nuova tabella non presente in GstCauzioni dove il campo SumImportoSvincolato era solo un totale cumulativo senza storico. Status=0=NON_AVVIATO (default). NON ha FK verso RegistroCauzioniStatus: validazione applicativa. Al completamento (Status=440), il layer applicativo aggiorna SumImportoSvincolato in RegistroCauzioni e, se uguale a ImpTotale, imposta StatusGenerale=CHIUSA.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniSvincolo'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Importo svincolato in questa specifica operazione. La somma di tutti i record completati per lo stesso IDRegistroCauzioni deve corrispondere a SumImportoSvincolato in RegistroCauzioni.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniSvincolo',
    @level2type=N'COLUMN', @level2name=N'ImportoSvincolato'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Stato del ciclo di svincolo. Valori in RegistroCauzioniStatus con CodSezione=''SVINCOLO''. DEFAULT=0=NON_AVVIATO. NON ha FK: validazione applicativa.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniSvincolo',
    @level2type=N'COLUMN', @level2name=N'Status'
GO
