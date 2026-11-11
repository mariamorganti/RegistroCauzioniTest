USE [DBRegistroCauzioni]
GO

/****** Tabella di lookup centralizzata degli stati per tutte le sezioni della Scheda Cauzione ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- TABELLA: RegistroCauzioniStatus
-- SCOPO: Lookup centralizzata degli stati per tutte le sezioni della Scheda Cauzione.
--        Copre sia gli stati generali (sezione 5.1) che gli stati delle singole sezioni
--        operative (sezione 5.2: Convalida, Variazioni, Proroghe, Svincolo, Escussione).
--
-- NOTA ARCHITETTURALE: Le tabelle di sezione (RegistroCauzioniConvalida, Variazioni, ecc.)
--        NON hanno FK verso questa tabella per scelta deliberata: la validazione degli stati
--        avviene a livello applicativo. Questo consente maggiore flessibilità nell'evoluzione
--        degli stati senza operazioni DDL sulle tabelle figlie.
--
-- ID=0 = INIZIALE (stato di default per tutte le sezioni al momento della creazione)
-- =============================================

CREATE TABLE [dbo].[RegistroCauzioniStatus](
    [IDStatus]          [smallint]      NOT NULL,
    [CodSezione]        [nvarchar](30)  NOT NULL,  -- es: GENERALE, CONVALIDA, VARIAZIONI, PROROGHE, SVINCOLO, ESCUSSIONE
    [CodStatus]         [nvarchar](50)  NOT NULL,  -- codice breve leggibile, es: INIZIALE, IN_ATTESA, IN_RITARDO
    [Descrizione]       [nvarchar](200) NOT NULL,
    [Ordine]            [smallint]      NOT NULL CONSTRAINT [DF_RegistroCauzioniStatus_Ordine] DEFAULT (0),
    [IsStatoFinale]     [bit]           NOT NULL CONSTRAINT [DF_RegistroCauzioniStatus_IsStatoFinale] DEFAULT (0),
    [IsStatoNegativo]   [bit]           NOT NULL CONSTRAINT [DF_RegistroCauzioniStatus_IsStatoNegativo] DEFAULT (0),
    [Note]              [nvarchar](500) NULL,
    [DataModifica]      [datetime2](7)  NOT NULL CONSTRAINT [DF_RegistroCauzioniStatus_DataModifica] DEFAULT (SYSDATETIME()),
    [IDOperatore]       [int]           NOT NULL,
 CONSTRAINT [PK_RegistroCauzioniStatus] PRIMARY KEY CLUSTERED
(
    [IDStatus] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
       ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90,
       OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_RegistroCauzioniStatus_CodSezione_CodStatus] UNIQUE NONCLUSTERED
(
    [CodSezione] ASC,
    [CodStatus]  ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
       ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- =============================================
-- DATI: Stati Generali della Cauzione (sezione 5.1)
-- =============================================
INSERT INTO [dbo].[RegistroCauzioniStatus]
    ([IDStatus],[CodSezione],[CodStatus],[Descrizione],[Ordine],[IsStatoFinale],[IsStatoNegativo],[Note],[IDOperatore])
VALUES
(  0, N'GENERALE', N'INIZIALE',      N'Scheda cauzione creata ma non ancora ricevuta alcuna documentazione.',                       0, 0, 0, N'Stato di default al momento della creazione del record.',     1),
( 10, N'GENERALE', N'DA_RICEVERE',   N'In attesa di ricezione della polizza/fideiussione originale.',                               1, 0, 0, NULL,                                                          1),
( 20, N'GENERALE', N'IN_ESSERE',     N'Polizza ricevuta, convalidata e attualmente in vigore.',                                     2, 0, 0, NULL,                                                          1),
( 30, N'GENERALE', N'IN_SCADENZA',   N'Scadenza entro la soglia di allerta configurata (default: 90 giorni). Semaforo GIALLO.',     3, 0, 1, N'Transizione automatica a evento notturno.',                  1),
( 40, N'GENERALE', N'SCADUTA',       N'Data di scadenza superata senza rinnovo o svincolo. Semaforo ROSSO.',                        4, 0, 1, N'Transizione automatica a evento notturno.',                  1),
( 50, N'GENERALE', N'IN_SVINCOLO',   N'Procedura di svincolo avviata.',                                                             5, 0, 0, NULL,                                                          1),
( 60, N'GENERALE', N'CHIUSA',        N'Cauzione conclusa: svincolo completato o escussione definitiva incamerata.',                 6, 1, 0, N'Stato finale. Record non più modificabile.',                  1);

-- =============================================
-- DATI: Stati Sezione Convalida (sezione 5.2.1)
-- =============================================
INSERT INTO [dbo].[RegistroCauzioniStatus]
    ([IDStatus],[CodSezione],[CodStatus],[Descrizione],[Ordine],[IsStatoFinale],[IsStatoNegativo],[Note],[IDOperatore])
VALUES
(100, N'CONVALIDA', N'NON_AVVIATA',         N'Sezione convalida non ancora avviata.',                                              0, 0, 0, NULL,                                                          1),
(110, N'CONVALIDA', N'IN_ATTESA_ORIGINALE', N'In attesa di ricezione dell''originale della polizza.',                              1, 0, 0, NULL,                                                          1),
(120, N'CONVALIDA', N'ORIGINALE_RICEVUTO',  N'Originale ricevuto; avviata verifica di conformità.',                                2, 0, 0, NULL,                                                          1),
(130, N'CONVALIDA', N'IN_ATTESA_ESITO',     N'Verifica di conformità in corso; in attesa di esito.',                              3, 0, 0, NULL,                                                          1),
(140, N'CONVALIDA', N'NON_CONFORME',        N'Verifica di conformità con esito negativo. Richiesta integrazione o rettifica.',     4, 0, 1, N'Semaforo ROSSO sul KPI Convalida.',                          1),
(150, N'CONVALIDA', N'IN_ATTESA_INTEGRAZ',  N'In attesa di ricezione dell''integrazione o rettifica da parte del fideiussore.',   5, 0, 0, NULL,                                                          1),
(160, N'CONVALIDA', N'CONFORME',            N'Verifica di conformità superata con esito positivo.',                                6, 0, 0, NULL,                                                          1),
(170, N'CONVALIDA', N'IN_RITARDO',          N'Superata la soglia temporale (default: 30 gg dall''invio PEC). Semaforo ROSSO.',    7, 0, 1, N'Transizione automatica a evento notturno.',                  1),
(180, N'CONVALIDA', N'INVALIDATA',          N'Polizza invalidata formalmente. Richiesta sostituzione.',                            8, 0, 1, NULL,                                                          1),
(190, N'CONVALIDA', N'COMPLETATA',          N'Convalida conclusa con validità confermata. Cauzione IN_ESSERE.',                   9, 1, 0, NULL,                                                          1);

-- =============================================
-- DATI: Stati Sezione Variazioni (sezione 5.2.2)
-- =============================================
INSERT INTO [dbo].[RegistroCauzioniStatus]
    ([IDStatus],[CodSezione],[CodStatus],[Descrizione],[Ordine],[IsStatoFinale],[IsStatoNegativo],[Note],[IDOperatore])
VALUES
(200, N'VARIAZIONI', N'NON_AVVIATA',       N'Nessuna richiesta di variazione in corso.',                                          0, 0, 0, NULL,                                                          1),
(210, N'VARIAZIONI', N'RICHIESTA_INVIATA', N'Richiesta di modifica contratto inviata al fideiussore.',                            1, 0, 0, NULL,                                                          1),
(220, N'VARIAZIONI', N'IN_RITARDO',        N'Superata la soglia temporale (default: 15 gg dalla richiesta). Semaforo ROSSO.',    2, 0, 1, N'Transizione automatica a evento notturno.',                  1),
(230, N'VARIAZIONI', N'INTEGRAZIONE_RIC',  N'Documentazione di variazione ricevuta; in corso di verifica.',                      3, 0, 0, NULL,                                                          1),
(240, N'VARIAZIONI', N'COMPLETATA',        N'Variazione validata e recepita. Dati della cauzione aggiornati.',                   4, 1, 0, NULL,                                                          1);

-- =============================================
-- DATI: Stati Sezione Proroghe (sezione 5.2.3)
-- =============================================
INSERT INTO [dbo].[RegistroCauzioniStatus]
    ([IDStatus],[CodSezione],[CodStatus],[Descrizione],[Ordine],[IsStatoFinale],[IsStatoNegativo],[Note],[IDOperatore])
VALUES
(300, N'PROROGHE', N'NON_AVVIATA',         N'Nessuna richiesta di proroga in corso.',                                             0, 0, 0, NULL,                                                          1),
(310, N'PROROGHE', N'IN_ISTRUTTORIA',      N'Richiesta di proroga del progetto in istruttoria interna.',                         1, 0, 0, NULL,                                                          1),
(320, N'PROROGHE', N'RICHIESTA_INVIATA',   N'Comunicazione di proroga inviata al fideiussore.',                                  2, 0, 0, NULL,                                                          1),
(330, N'PROROGHE', N'IN_ATTESA_RINNOVO',   N'In attesa di ricezione del documento di rinnovo/proroga da fideiussore.',           3, 0, 0, NULL,                                                          1),
(340, N'PROROGHE', N'IN_RITARDO',          N'Superata la soglia temporale (default: 15 gg dalla richiesta). Semaforo ROSSO.',   4, 0, 1, N'Transizione automatica a evento notturno.',                  1),
(350, N'PROROGHE', N'RINNOVO_RICEVUTO',    N'Documento di proroga/rinnovo ricevuto; in corso di verifica.',                     5, 0, 0, NULL,                                                          1),
(360, N'PROROGHE', N'CONFERMATA',          N'Proroga verificata e confermata. Scadenze aggiornate.',                             6, 1, 0, NULL,                                                          1),
(370, N'PROROGHE', N'RIFIUTATA',           N'Fideiussore ha rifiutato la proroga. Richiesta azione alternativa.',                7, 1, 1, N'Stato finale negativo. Avviare procedura alternativa.',       1),
(380, N'PROROGHE', N'ANNULLATA',           N'Proroga annullata internamente prima del completamento.',                           8, 1, 0, NULL,                                                          1);

-- =============================================
-- DATI: Stati Sezione Svincolo (sezione 5.2.4)
-- =============================================
INSERT INTO [dbo].[RegistroCauzioniStatus]
    ([IDStatus],[CodSezione],[CodStatus],[Descrizione],[Ordine],[IsStatoFinale],[IsStatoNegativo],[Note],[IDOperatore])
VALUES
(400, N'SVINCOLO', N'NON_AVVIATO',         N'Procedura di svincolo non ancora avviata.',                                          0, 0, 0, NULL,                                                          1),
(410, N'SVINCOLO', N'AUTORIZZATO',         N'Svincolo autorizzato internamente; in attesa di comunicazione al fideiussore.',      1, 0, 0, NULL,                                                          1),
(420, N'SVINCOLO', N'COMUNICAZIONE_INVIATA',N'Lettera/PEC di svincolo inviata al fideiussore.',                                  2, 0, 0, NULL,                                                          1),
(430, N'SVINCOLO', N'PARZIALE',            N'Svincolo parziale completato. Importo residuo ancora garantito.',                   3, 0, 0, NULL,                                                          1),
(440, N'SVINCOLO', N'COMPLETATO',          N'Svincolo totale completato. Cauzione transita in stato CHIUSA.',                    4, 1, 0, N'Trigger applicativo: aggiorna StatusGenerale→CHIUSA.',        1);

-- =============================================
-- DATI: Stati Sezione Escussione (sezione 5.2.5)
-- =============================================
INSERT INTO [dbo].[RegistroCauzioniStatus]
    ([IDStatus],[CodSezione],[CodStatus],[Descrizione],[Ordine],[IsStatoFinale],[IsStatoNegativo],[Note],[IDOperatore])
VALUES
(500, N'ESCUSSIONE', N'NON_AVVIATA',       N'Nessuna procedura di escussione in corso.',                                          0, 0, 0, NULL,                                                          1),
(510, N'ESCUSSIONE', N'AVVISI_INVIATI',    N'Avvisi di escussione inviati a debitore e garante.',                                1, 0, 0, NULL,                                                          1),
(520, N'ESCUSSIONE', N'LETTERA_INVIATA',   N'Lettera formale di escussione inviata al fideiussore.',                             2, 0, 1, N'Semaforo ROSSO.',                                            1),
(530, N'ESCUSSIONE', N'IN_RITARDO',        N'Superata la soglia temporale (default: 60 gg dalla lettera). Semaforo ROSSO.',     3, 0, 1, N'Transizione automatica a evento notturno.',                  1),
(540, N'ESCUSSIONE', N'PARZIALE',          N'Importo parzialmente incamerato. Procedura ancora aperta.',                        4, 0, 1, NULL,                                                          1),
(550, N'ESCUSSIONE', N'COMPLETATA',        N'Importo totale richiesto incamerato. Cauzione transita in CHIUSA.',                 5, 1, 0, N'Trigger applicativo: aggiorna StatusGenerale→CHIUSA.',        1),
(560, N'ESCUSSIONE', N'LETTERA_RESTITUZ',  N'Lettera di restituzione/svincolo residuo inviata al termine dell''escussione.',    6, 1, 0, NULL,                                                          1);
GO

-- =============================================
-- Extended Properties
-- =============================================
EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Lookup centralizzata degli stati per tutte le sezioni della Scheda Cauzione (stati generali 5.1 e stati di sezione 5.2). Le tabelle operative NON hanno FK verso questa tabella: la validazione è applicativa. ID=0=INIZIALE è il default universale.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniStatus'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Identificativo numerico dello stato. Convenzione: 0=INIZIALE; 10-60=stati generali; 100-190=Convalida; 200-240=Variazioni; 300-380=Proroghe; 400-440=Svincolo; 500-560=Escussione.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniStatus',
    @level2type=N'COLUMN', @level2name=N'IDStatus'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Sezione di pertinenza dello stato: GENERALE, CONVALIDA, VARIAZIONI, PROROGHE, SVINCOLO, ESCUSSIONE.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniStatus',
    @level2type=N'COLUMN', @level2name=N'CodSezione'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Se 1, lo stato è finale: il record della sezione non può più avanzare ad altri stati (es: COMPLETATA, CHIUSA, RIFIUTATA).',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniStatus',
    @level2type=N'COLUMN', @level2name=N'IsStatoFinale'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Se 1, lo stato richiede attenzione operativa urgente (semaforo ROSSO o GIALLO nella Dashboard KPI).',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniStatus',
    @level2type=N'COLUMN', @level2name=N'IsStatoNegativo'
GO
