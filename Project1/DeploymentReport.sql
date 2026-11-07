/*
Script di distribuzione per RegistroCauzioniTest

Questo codice è stato generato da uno strumento.
Le modifiche apportate a questo file possono causare un comportamento non corretto e andranno perse se
il codice viene rigenerato.
*/

GO
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;

SET NUMERIC_ROUNDABORT OFF;


GO
:setvar DatabaseName "RegistroCauzioniTest"
:setvar DefaultFilePrefix "RegistroCauzioniTest"
:setvar DefaultDataPath "C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER2025\MSSQL\DATA\"
:setvar DefaultLogPath "C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER2025\MSSQL\DATA\"

GO
:on error exit
GO
/*
Rilevare la modalità SQLCMD e disabilitare l'esecuzione dello script se la modalità SQLCMD non è supportata.
Per riabilitare lo script dopo aver abilitato la modalità SQLCMD, eseguire quanto segue:
IMPOSTARE NOEXEC SU OFF; 
*/
:setvar __IsSqlCmdEnabled "True"
GO
IF N'$(__IsSqlCmdEnabled)' NOT LIKE N'True'
    BEGIN
        PRINT N'Per la corretta esecuzione dello script è necessario abilitare la modalità SQLCMD.';
        SET NOEXEC ON;
    END


GO
USE [$(DatabaseName)];


GO
PRINT N'Aggiornamento completato.';


GO
