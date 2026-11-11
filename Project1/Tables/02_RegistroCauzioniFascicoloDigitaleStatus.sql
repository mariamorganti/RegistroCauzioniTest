USE [DBRegistroCauzioni]
GO

/****** Tabella di lookup degli stati del Fascicolo Digitale (nuova sezione 3.4.10) ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- TABELLA: RegistroCauzioniFascicoloDigitaleStatus
-- SCOPO: Lookup degli stati del ciclo di vita di un documento nel Fascicolo Digitale.
--        Separata dalla tabella generale RegistroCauzioniStatus perché il Fascicolo
--        Digitale ha un ciclo di vita proprio indipendente dalla cauzione.
--
-- NOTA ARCHITETTURALE: La tabella RegistroCauzioniFascicoloDigitale NON ha FK
--        verso questa tabella: la validazione degli stati avviene a livello applicativo.
--
-- ID=0 = BOZZA (stato di default al momento del caricamento del documento)
-- =============================================

CREATE TABLE [dbo].[RegistroCauzioniFascicoloDigitaleStatus](
    [IDStatus]          [smallint]      NOT NULL,
    [CodStatus]         [nvarchar](50)  NOT NULL,
    [Descrizione]       [nvarchar](200) NOT NULL,
    [Ordine]            [smallint]      NOT NULL CONSTRAINT [DF_FascicoloDigitaleStatus_Ordine] DEFAULT (0),
    [IsStatoFinale]     [bit]           NOT NULL CONSTRAINT [DF_FascicoloDigitaleStatus_IsStatoFinale] DEFAULT (0),
    [Note]              [nvarchar](500) NULL,
    [DataModifica]      [datetime2](7)  NOT NULL CONSTRAINT [DF_FascicoloDigitaleStatus_DataModifica] DEFAULT (SYSDATETIME()),
    [IDOperatore]       [int]           NOT NULL,
 CONSTRAINT [PK_RegistroCauzioniFascicoloDigitaleStatus] PRIMARY KEY CLUSTERED
(
    [IDStatus] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
       ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90,
       OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_FascicoloDigitaleStatus_CodStatus] UNIQUE NONCLUSTERED
(
    [CodStatus] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
       ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- =============================================
-- DATI: Stati del ciclo di vita del documento nel Fascicolo Digitale
-- =============================================
INSERT INTO [dbo].[RegistroCauzioniFascicoloDigitaleStatus]
    ([IDStatus],[CodStatus],[Descrizione],[Ordine],[IsStatoFinale],[Note],[IDOperatore])
VALUES
(0, N'BOZZA',      N'Documento caricato in bozza; non ancora firmato né inviato. Modificabile.',                              0, 0, N'Stato di default al momento del caricamento.',          1),
(1, N'FIRMATO',    N'Documento firmato digitalmente (firma elettronica qualificata). Non più modificabile.',                   1, 0, NULL,                                                     1),
(2, N'INVIATO_PEC',N'Documento trasmesso via PEC al fideiussore o all''ente ricevente.',                                      2, 0, N'Al cambio stato registrare protocollo e data PEC.',    1),
(3, N'RICEVUTO',   N'Ricezione confermata. Documento archiviato definitivamente nel fascicolo.',                              3, 1, N'Stato finale. Documento non modificabile né cancellabile.',1),
(4, N'ANNULLATO',  N'Documento annullato prima dell''invio. Sostituito da versione successiva.',                              4, 1, N'Stato finale negativo. Il documento resta in archivio per audit.', 1);
GO

-- =============================================
-- Extended Properties
-- =============================================
EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Lookup degli stati del ciclo di vita di un documento nel Fascicolo Digitale (sezione 3.4.10 TO BE). ID=0=BOZZA è il default al caricamento. La tabella RegistroCauzioniFascicoloDigitale NON ha FK verso questa tabella: validazione applicativa.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniFascicoloDigitaleStatus'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'0=BOZZA, 1=FIRMATO, 2=INVIATO_PEC, 3=RICEVUTO (finale), 4=ANNULLATO (finale).',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniFascicoloDigitaleStatus',
    @level2type=N'COLUMN', @level2name=N'IDStatus'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Se 1, il documento ha raggiunto uno stato finale e non può essere modificato né cancellato (conservazione a norma).',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniFascicoloDigitaleStatus',
    @level2type=N'COLUMN', @level2name=N'IsStatoFinale'
GO
