SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[GstCauzioniNew] (
    [NIdentificativoInterno]      INT IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
    [DataIdentificativo]          DATETIME2(7) CONSTRAINT [DF_GstCauzioniNew_DataIdentificativo] DEFAULT (SYSDATETIME()) NOT NULL,
    [NumIns]                      INT NOT NULL,
    [AnnoIns]                     SMALLINT NOT NULL,
    [FlagInEssere]                BIT CONSTRAINT [DF_GstCauzioniNew_FlagInEssere] DEFAULT ((0)) NOT NULL,
    [IDTipoDomandaModulo]         INT NULL,
    [NDomandaModulo]              NVARCHAR(50) NULL,
    [IDTipoDomanda]               INT NOT NULL,
    [NDomanda]                    NVARCHAR(50) NOT NULL,
    [NPolizza]                    NVARCHAR(50) NULL,
    [DataPolizza]                 DATETIME2(3) NULL,
    [ScadenzaPolizza]             DATETIME2(3) NULL,
    [ScadenzaProgetto]            DATETIME2(3) NULL,
    [DataProrogaProgetto]         DATETIME2(3) NULL,
    [ProtComunicazioneProroga]    NVARCHAR(30) NULL,
    [DataComunicazioneProroga]    DATETIME2(3) NULL,
    [ScadenzaUltimoRinnovo]        DATETIME2(3) NULL,
    
    [ImpTotale]                   DECIMAL(18,2) CONSTRAINT [DF_GstCauzioniNew_ImpTotale] DEFAULT ((0)) NOT NULL,
    [ImpFEOGA]                    DECIMAL(18,2) CONSTRAINT [DF_GstCauzioniNew_ImpFEOGA] DEFAULT ((0)) NOT NULL,
    [ImpQuotaStato]               DECIMAL(18,2) CONSTRAINT [DF_GstCauzioniNew_ImpQuotaStato] DEFAULT ((0)) NOT NULL,
    [ImpQuotaRegione]             DECIMAL(18,2) CONSTRAINT [DF_GstCauzioniNew_ImpQuotaRegione] DEFAULT ((0)) NOT NULL,
    [ImpCapitale]                 DECIMAL(18,2) CONSTRAINT [DF_GstCauzioniNew_ImpCapitale] DEFAULT ((0)) NOT NULL,
    [ImpInteressiSpese]           DECIMAL(18,2) CONSTRAINT [DF_GstCauzioniNew_ImpInteressiSpese] DEFAULT ((0)) NOT NULL,
    [ImpIntSpeseFEOGA]            DECIMAL(18,2) CONSTRAINT [DF_GstCauzioniNew_ImpIntSpeseFEOGA] DEFAULT ((0)) NOT NULL,
    
    [DataConcServTec]             DATETIME2(3) NULL,
    [IDTipoCauzione]              INT NOT NULL,
    [IDFideiussore]               INT NOT NULL,
    [AgenziaFideiussore]          NVARCHAR(150) NULL,
    [CFAgenziaFideiussore]        NVARCHAR(16) NULL,
    [IndirizzoAgenziaFideiussore] NVARCHAR(150) NULL,
    [PIVAAgenziaFideiussore]      NVARCHAR(11) NULL, 
    [Note]                        NVARCHAR(1000) NULL,
    [ApprovatoCheckList]          BIT CONSTRAINT [DF_GstCauzioniNew_ApprovatoCheckList] DEFAULT ((0)) NOT NULL,
    [DataModifica]                DATETIME2(7) CONSTRAINT [DF_GstCauzioniNew_DataModifica] DEFAULT (SYSDATETIME()) NOT NULL,
    [IDOperatore]                 INT NOT NULL,
    [CupArtea]                    NVARCHAR(255) NULL,

    -- Vincoli interni (Primary Key e Unique Key)
    CONSTRAINT [PK_GstCauzioniNew] PRIMARY KEY CLUSTERED ([NIdentificativoInterno] ASC),
    CONSTRAINT [IX_GstCauzioniNew_LogicKey] UNIQUE NONCLUSTERED ([NumIns] ASC, [AnnoIns] ASC),

    -- Check Constraint
    CONSTRAINT [CK_GstCauzioniNew_AnnoIns] CHECK ([AnnoIns] >= 1753 AND [AnnoIns] <= 9999)
) ON [PRIMARY];
GO

-- Extended Properties per la documentazione delle colonne
EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', @value=N'Codice identificativo della tipologia di procedimento (decodifica in CodTipoDomanda)', 
    @level0type=N'SCHEMA', @level0name=N'dbo', 
    @level1type=N'TABLE',  @level1name=N'GstCauzioniNew', 
    @level2type=N'COLUMN', @level2name=N'IDTipoDomanda';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', @value=N'Codice identificativo della domanda di aiuto (vd tabella Domanda)', 
    @level0type=N'SCHEMA', @level0name=N'dbo', 
    @level1type=N'TABLE',  @level1name=N'GstCauzioniNew', 
    @level2type=N'COLUMN', @level2name=N'NDomanda';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', @value=N'Eventuali annotazioni relative al record', 
    @level0type=N'SCHEMA', @level0name=N'dbo', 
    @level1type=N'TABLE',  @level1name=N'GstCauzioniNew', 
    @level2type=N'COLUMN', @level2name=N'Note';
GO

EXEC sys.sp_addextendedproperty 
    @name=N'MS_Description', @value=N'Data di ultima modifica del record', 
    @level0type=N'SCHEMA', @level0name=N'dbo', 
    @level1type=N'TABLE',  @level1name=N'GstCauzioniNew', 
    @level2type=N'COLUMN', @level2name=N'DataModifica';
GO