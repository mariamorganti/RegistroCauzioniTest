CREATE TABLE [dbo].[DocFascicolo](
    [IDFascicolo] [bigint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
    [IdTipoDocumento] [int] NOT NULL,
    [IDTipoDomanda] [int] NULL,
    [NDomanda] [nvarchar](50) NULL,
    [IdFascicoloTestata] [bigint] NULL,
    [FlagGestioneAutomatica] [bit] NOT NULL,
    [NIdentificativo] [int] NULL,
    [DataDocumento] [datetime2](7) NOT NULL,
    [DataScadenzaDocumento] [datetime2](7) NULL,
    [CodiceBarre] [varchar](50) NULL,
    [Valore1] [nvarchar](255) NULL,
    [Valore2] [nvarchar](255) NULL,
    [Valore3] [nvarchar](255) NULL,
    [Valore4] [nvarchar](255) NULL,
    [Valore5] [nvarchar](255) NULL,
    [Valore6] [nvarchar](255) NULL,
    [Valore7] [nvarchar](255) NULL,
    [Valore8] [nvarchar](255) NULL,
    [Valore9] [nvarchar](255) NULL,
    [Valore10] [nvarchar](255) NULL,
    [Osservazioni] [nvarchar](max) NULL,
    [DataInizioValidita] [datetime2](7) NULL,
    [DataFineValidita] [datetime2](7) NULL,
    [IDUtente] [int] NOT NULL,
    [DataModifica] [datetime2](7) NULL,
    [IdUtenteCertificatore] [int] NULL,
    [DataCertificazione] [datetime2](7) NULL,
    [NewIdFascicolo] [bigint] NULL,
    [IdOrganizzazioneLocazione] [int] NULL,
    [IdUtenteAssegnatario] [int] NULL,
    [Valore11] [nvarchar](255) NULL,
    [Valore12] [nvarchar](255) NULL,
    [Valore13] [nvarchar](255) NULL,
    [Valore14] [nvarchar](255) NULL,
    [Valore15] [nvarchar](255) NULL,
    [Valore16] [nvarchar](255) NULL,
    [Valore17] [nvarchar](255) NULL,
    [Valore18] [nvarchar](255) NULL,
    [Valore19] [nvarchar](255) NULL,
    [Valore20] [nvarchar](255) NULL,
    [CodCategoria] [char](2) NULL,
 CONSTRAINT [PK_DocFascicolo] PRIMARY KEY CLUSTERED 
(
    [IDFascicolo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[DocFascicolo] ADD CONSTRAINT [DF_DocFascicolo_FlagGestioneAutomatica] DEFAULT (0) FOR [FlagGestioneAutomatica]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Codice identificativo della tipologia di procedimento (decodifica in CodTipoDomanda)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'DocFascicolo', @level2type=N'COLUMN',@level2name=N'IDTipoDomanda'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Codice identificativo della domanda di aiuto (vd tabella Domanda)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'DocFascicolo', @level2type=N'COLUMN',@level2name=N'NDomanda'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Eventuali annotazioni relative al record' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'DocFascicolo', @level2type=N'COLUMN',@level2name=N'Osservazioni'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Data di inizio della validita del record, può indicare la data di inserimento o una data convenzionale' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'DocFascicolo', @level2type=N'COLUMN',@level2name=N'DataInizioValidita'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Data di fine della validita del record (cancellazione logica), il record valido ha un valore di 31/12/9999' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'DocFascicolo', @level2type=N'COLUMN',@level2name=N'DataFineValidita'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Identificativo utente che ha inserito/modificato per ultimo il record' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'DocFascicolo', @level2type=N'COLUMN',@level2name=N'IDUtente'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Data di ultima modifica del record' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'DocFascicolo', @level2type=N'COLUMN',@level2name=N'DataModifica'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'ID del documento di provenienza dalla domanda' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'DocFascicolo', @level2type=N'COLUMN',@level2name=N'NewIdFascicolo'
GO