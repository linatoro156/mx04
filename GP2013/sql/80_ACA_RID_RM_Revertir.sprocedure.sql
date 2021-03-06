SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (
  SELECT * 
    FROM INFORMATION_SCHEMA.ROUTINES 
   WHERE SPECIFIC_SCHEMA = 'dbo'
     AND SPECIFIC_NAME = 'ACA_RID_RM_Revertir' 
)
   DROP PROCEDURE dbo.[ACA_RID_RM_Revertir];
GO

create PROCEDURE [dbo].[ACA_RID_RM_Revertir] @VCHRNMBR CHAR(21), @TRXDATE datetime, @BACHNUMB CHAR(15), @USERID CHAR(15)
AS
-- EXEC ACA_RID_RM_Revertir 'RC000100000021', '20130101', '13010207', 'sa'
PRINT @VCHRNMBR
PRINT @TRXDATE
print @BACHNUMB
print @USERID

DECLARE @ORIGEN smallint, @JRNENTRY0 int, @BCHTOTAL NUMERIC(19,5)
DECLARE @l_tINCheckWORKFiles tinyint, @I_iSQLSessionID int, @IO_iOUTJournalEntry int, @O_tOUTOK tinyint, @O_iErrorState int
DECLARE @SEQNUMBR INT, @DEBITAMT numeric(19, 5), @CRDTAMNT numeric(19, 5), @ORDBTAMT numeric(19, 5), @ORCRDAMT NUMERIC(19, 5)
DECLARE @SOURCDOC CHAR(11), @I_sCompanyID smallint, @ACTINDX int
DECLARE @O_nDTAIndex numeric(19,5), @O_mNoteIndex numeric(19,5), @SQNCLINE numeric(19, 5)
DECLARE @SENIAL INT, @iNTERID CHAR(5), @CURNCYID CHAR(15), @CURRNIDX int, @MCTRXSTT smallint
DECLARE @RATETPID char(15), @EXGTBLID char(15), @EXCHDATE datetime, @YEAR1 INT, @PERIODID SMALLINT, @TIME1 datetime
DECLARE @XCHGRATE numeric(19, 7), @RTCLCMTD smallint, @DECPLACS smallint, @EXPNDATE datetime, @DENXRATE numeric(19, 7)
DECLARE @ORMSTRID CHAR(15), @ORMSTRNM CHAR(64), @RECLASIFICADO tinyint
select @I_sCompanyID = CMPANYID FROM DYNAMICS..SY01500 WHERE INTERID = DB_NAME()

SELECT TOP 1 @SOURCDOC = SOURCDOC FROM SY01000 WHERE TRXSRCPX IN('GLTRN', 'GLTRX')

SELECT @ORIGEN = ACA_RID_Origen, @JRNENTRY0 = JRNENTRY FROM ACA_RID10000 WHERE VCHRNMBR = @VCHRNMBR AND TXDTLTYP = 1 AND ACA_RID_Last = 1

SELECT @l_tINCheckWORKFiles = 0
SELECT @I_iSQLSessionID = 0
SELECT @IO_iOUTJournalEntry = 0

SELECT @ORMSTRID = A.CUSTNMBR, @ORMSTRNM = CUSTNAME FROM RM00101 A INNER JOIN RM00401 B ON A.CUSTNMBR = B.CUSTNMBR WHERE B.DOCNUMBR = @VCHRNMBR AND B.RMDTYPAL = 9

CREATE TABLE #TEMP
	(
	[SEQNUMBR] [int] NOT NULL,
	[ACTINDX] [int] NOT NULL,
	[DEBITAMT] [numeric](19, 5) NOT NULL,
	[CRDTAMNT] [numeric](19, 5) NOT NULL,
	[ORDBTAMT] [numeric](19, 5) NOT NULL,
	[ORCRDAMT] [numeric](19, 5) NOT NULL,
	[INTERID] [char](5) NOT NULL,
	[CURNCYID] [char](15) NOT NULL,
	[CURRNIDX] [smallint] NOT NULL,
	[RATETPID] [char](15) NOT NULL,
	[EXGTBLID] [char](15) NOT NULL,
	[XCHGRATE] [numeric](19, 7) NOT NULL,
	[EXCHDATE] [datetime] NOT NULL,
	[TIME1] [datetime] NOT NULL,
	[RTCLCMTD] [smallint] NOT NULL,
	[DECPLACS] [smallint] NOT NULL,
	[EXPNDATE] [datetime] NOT NULL,
	[DENXRATE] [numeric](19, 7) NOT NULL,
	[MCTRXSTT] [smallint] NOT NULL,
	[DEX_ROW_ID] [int] IDENTITY(1,1) NOT NULL
	)

if @ORIGEN = 1
BEGIN
	IF EXISTS(SELECT DOCNUMBR FROM RM20101 WHERE DOCNUMBR = @VCHRNMBR AND RMDTYPAL = 9)
	BEGIN
		INSERT INTO #TEMP SELECT SEQNUMBR, DSTINDX ACTINDX, CRDTAMNT DEBITAMT, DEBITAMT CRDTAMNT, ORCRDAMT ORDBTAMT, ORDBTAMT ORCRDAMT, DB_NAME() INTERID, A.CURNCYID, A.CURRNIDX, ISNULL(C.RATETPID, ''),
			ISNULL(C.EXGTBLID, ''), ISNULL(C.XCHGRATE, 1), ISNULL(C.EXCHDATE, 0), ISNULL(C.TIME1, 0), ISNULL(C.RTCLCMTD, 0), D.DECPLCUR-1, 0, ISNULL(C.DENXRATE, 0), ISNULL(C.MCTRXSTT, 0)
		FROM RM10101 A INNER JOIN RM20101 B ON A.DOCNUMBR = B.DOCNUMBR 
		LEFT OUTER JOIN MC020102 C ON A.RMDTYPAL = C.RMDTYPAL AND A.DOCNUMBR = C.DOCNUMBR
		INNER JOIN DYNAMICS..MC40200 D ON A.CURNCYID = D.CURNCYID
		WHERE A.DOCNUMBR = @VCHRNMBR 
		AND A.RMDTYPAL = 9 AND A.DISTTYPE = 8
	END

	IF EXISTS(SELECT DOCNUMBR FROM RM30101 WHERE DOCNUMBR = @VCHRNMBR AND RMDTYPAL = 9)
	BEGIN
		INSERT INTO #TEMP SELECT SEQNUMBR, DSTINDX ACTINDX, CRDTAMNT DEBITAMT, DEBITAMT CRDTAMNT, ORCRDAMT ORDBTAMT, ORDBTAMT ORCRDAMT, DB_NAME() INTERID, A.CURNCYID, A.CURRNIDX, ISNULL(C.RATETPID, ''),
			ISNULL(C.EXGTBLID, ''), ISNULL(C.XCHGRATE, 1), ISNULL(C.EXCHDATE, 0), ISNULL(C.TIME1, 0), ISNULL(C.RTCLCMTD, 0), D.DECPLCUR-1, 0, ISNULL(C.DENXRATE, 0), ISNULL(C.MCTRXSTT, 0)
		FROM RM30301 A INNER JOIN RM30101 B ON A.DOCNUMBR = B.DOCNUMBR 
		LEFT OUTER JOIN MC020102 C ON A.RMDTYPAL = C.RMDTYPAL AND A.DOCNUMBR = C.DOCNUMBR
		INNER JOIN DYNAMICS..MC40200 D ON A.CURNCYID = D.CURNCYID
		WHERE A.DOCNUMBR = @VCHRNMBR 
		AND A.RMDTYPAL = 9 AND A.DISTTYPE = 8
	END

END
ELSE
BEGIN
	IF EXISTS(SELECT JRNENTRY FROM GL10000 WHERE JRNENTRY = @JRNENTRY0)
	BEGIN
		INSERT INTO #TEMP SELECT B.SQNCLINE, B.ACTINDX, CRDTAMNT DEBITAMT, DEBITAMT CRDTAMNT, ORCRDAMT ORDBTAMT, ORDBTAMT ORCRDAMT, DB_NAME() INTERID, A.CURNCYID, A.CURRNIDX, A.RATETPID,
			A.EXGTBLID, A.XCHGRATE, A.EXCHDATE, A.TIME1, A.RTCLCMTD, D.DECPLCUR-1 DECPLACS, '19000101' EXPNDATE, A.DENXRATE, A.MCTRXSTT
		FROM GL10000 A INNER JOIN GL10001 B ON A.JRNENTRY = B.JRNENTRY INNER JOIN DYNAMICS..MC40200 D ON A.CURNCYID = D.CURNCYID
		WHERE A.JRNENTRY = @JRNENTRY0
	END
	IF EXISTS(SELECT JRNENTRY FROM GL20000 WHERE JRNENTRY = @JRNENTRY0)
	BEGIN
		INSERT INTO #TEMP SELECT SEQNUMBR, A.ACTINDX, CRDTAMNT DEBITAMT, DEBITAMT CRDTAMNT, ORCRDAMT ORDBTAMT, ORDBTAMT ORCRDAMT, DB_NAME() INTERID, A.CURNCYID, A.CURRNIDX, A.RATETPID,
			A.EXGTBLID, A.XCHGRATE, A.EXCHDATE, A.TIME1, A.RTCLCMTD, D.DECPLCUR-1 DECPLACS, '19000101' EXPNDATE, A.DENXRATE, A.MCTRXSTT
		FROM GL20000 A INNER JOIN DYNAMICS..MC40200 D ON A.CURNCYID = D.CURNCYID
		WHERE A.JRNENTRY = @JRNENTRY0
	END
	IF EXISTS(SELECT JRNENTRY FROM GL30000 WHERE JRNENTRY = @JRNENTRY0)
	BEGIN
		INSERT INTO #TEMP SELECT SEQNUMBR, A.ACTINDX, CRDTAMNT DEBITAMT, DEBITAMT CRDTAMNT, ORCRDAMT ORDBTAMT, ORDBTAMT ORCRDAMT, DB_NAME() INTERID, A.CURNCYID, A.CURRNIDX, A.RATETPID,
			A.EXGTBLID, A.XCHGRATE, A.EXCHDATE, A.TIME1, A.RTCLCMTD, D.DECPLCUR-1 DECPLACS, '19000101' EXPNDATE, A.DENXRATE, A.MCTRXSTT
		FROM GL30000 A INNER JOIN DYNAMICS..MC40200 D ON A.CURNCYID = D.CURNCYID
		WHERE A.JRNENTRY = @JRNENTRY0
	END
END

if NOT EXISTS(SELECT SEQNUMBR FROM #TEMP) 
BEGIN 
	PRINT 'NOT EXISTS'
	RETURN
END

SELECT @SQNCLINE = 0

SELECT @SENIAL = 0

select @PERIODID=PERIODID from SY40100 where series = 2 and @TRXDATE BETWEEN PERIODDT AND PERDENDT AND ODESCTN = 'General Entry'

select @YEAR1=YEAR1 from SY40100 where series = 2 and @TRXDATE BETWEEN PERIODDT AND PERDENDT AND ODESCTN = 'General Entry'

SELECT @BCHTOTAL = 0

DECLARE LINEAS CURSOR FOR SELECT SEQNUMBR, ACTINDX, ISNULL(DEBITAMT, 0), ISNULL(CRDTAMNT, 0), ISNULL(ORDBTAMT, 0), ISNULL(ORCRDAMT, 0), INTERID, CURNCYID, CURRNIDX, RATETPID,
			EXGTBLID, XCHGRATE, EXCHDATE, TIME1, RTCLCMTD, DECPLACS, EXPNDATE, DENXRATE, MCTRXSTT FROM #TEMP
OPEN LINEAS
FETCH NEXT FROM LINEAS INTO @SEQNUMBR, @ACTINDX, @DEBITAMT, @CRDTAMNT, @ORDBTAMT, @ORCRDAMT, @INTERID, @CURNCYID, @CURRNIDX, @RATETPID,
			@EXGTBLID, @XCHGRATE, @EXCHDATE, @TIME1, @RTCLCMTD, @DECPLACS, @EXPNDATE, @DENXRATE, @MCTRXSTT
IF @@FETCH_STATUS = 0 BEGIN SELECT @RECLASIFICADO = 1 END ELSE BEGIN SELECT @RECLASIFICADO = 0 END
WHILE @@FETCH_STATUS = 0
BEGIN
	IF @SENIAL = 0
	BEGIN
	
		EXEC glGetNextJournalEntry @l_tINCheckWORKFiles, @I_iSQLSessionID, @IO_iOUTJournalEntry output, @O_tOUTOK, @O_iErrorState output

		EXEC dtaGetDTAIndex @IO_iOUTJournalEntry, @O_nDTAIndex output,  @O_iErrorState output 

		EXEC DYNAMICS..smGetNextNoteIndex @I_sCompanyID,  @I_iSQLSessionID, @O_mNoteIndex output, @O_iErrorState

		IF NOT EXISTS(SELECT BACHNUMB FROM GL10000 WHERE JRNENTRY = @IO_iOUTJournalEntry)
		BEGIN
			INSERT INTO GL10000 (BACHNUMB, BCHSOURC, JRNENTRY, SOURCDOC, REFRENCE, TRXDATE, PSTGSTUS, LASTUSER, LSTDTEDT, SERIES, DTA_Index,
				CURNCYID, CURRNIDX, RATETPID, EXGTBLID, XCHGRATE, EXCHDATE, TIME1, NOTEINDX, PERIODID, OPENYEAR, PRNTSTUS, Tax_Date)
				SELECT @BACHNUMB, 'GL_Normal' BCHSOURC, @IO_iOUTJournalEntry, @SOURCDOC, 'Rev: ' + @VCHRNMBR, @TRXDATE, 1 PSTGSTUS, @USERID,
				CONVERT(CHAR(8), GETDATE(), 112), 2 SERIES, @O_nDTAIndex, @CURNCYID, @CURRNIDX, @RATETPID, @EXGTBLID, @XCHGRATE, @EXCHDATE, @TIME1, 
				@O_mNoteIndex, @PERIODID PERIODID, @YEAR1 OPENYEAR, 1 PRNTSTUS, @TRXDATE Tax_Date
		END

		SELECT @SENIAL = 1
	END

	SELECT @BCHTOTAL = @BCHTOTAL + @DEBITAMT + @CRDTAMNT

	SELECT @SQNCLINE = @SQNCLINE + 500

	INSERT INTO GL10001 (BACHNUMB, JRNENTRY, SQNCLINE, ACTINDX, XCHGRATE, CURRNIDX, ACCTTYPE, DECPLACS, ORTRXTYP, ORCTRNUM, ORDOCNUM, ORMSTRID, 
			ORMSTRNM, INTERID, RATETPID, EXGTBLID, EXCHDATE, TIME1, RTCLCMTD, CRDTAMNT, DEBITAMT, ORCRDAMT, ORDBTAMT,
			DENXRATE, MCTRXSTT, LNESTAT)
			SELECT @BACHNUMB, @IO_iOUTJournalEntry, @SQNCLINE, @ACTINDX, @XCHGRATE, @CURRNIDX, 1 ACCTTYPE, @DECPLACS, 6 ORTRXTYP, @VCHRNMBR, 
				@VCHRNMBR, @ORMSTRID, @ORMSTRNM, DB_NAME(), @RATETPID, @EXGTBLID, @EXCHDATE, @TIME1, @RTCLCMTD, @CRDTAMNT, @DEBITAMT, @ORCRDAMT,
				@ORDBTAMT, @DENXRATE, @MCTRXSTT, 5 LNESTAT
	FETCH NEXT FROM LINEAS INTO @SEQNUMBR, @ACTINDX, @DEBITAMT, @CRDTAMNT, @ORDBTAMT, @ORCRDAMT, @INTERID, @CURNCYID, @CURRNIDX, @RATETPID,
			@EXGTBLID, @XCHGRATE, @EXCHDATE, @TIME1, @RTCLCMTD, @DECPLACS, @EXPNDATE, @DENXRATE, @MCTRXSTT

END
CLOSE LINEAS
DEALLOCATE LINEAS

PRINT @BCHTOTAL
PRINT @BACHNUMB

IF EXISTS(SELECT JRNENTRY FROM GL10001 WHERE JRNENTRY = @IO_iOUTJournalEntry)
BEGIN
	UPDATE SY00500 SET NUMOFTRX = NUMOFTRX + 1, BCHTOTAL = BCHTOTAL + @BCHTOTAL WHERE BACHNUMB = @BACHNUMB AND BCHSOURC = 'GL_Normal'

	UPDATE GL10000 SET SQNCLINE = @SQNCLINE WHERE JRNENTRY = @IO_iOUTJournalEntry

	INSERT INTO GL50101
	select @USERID, BCHSOURC, A.BACHNUMB, A.JRNENTRY, A.SQNCLINE, A.ACTINDX, 0 OFFINDX, GLLINMSG, GLLINMS2, TRXDATE, A.ACCTTYPE, DSCRIPTN, CURNCYID, A.CURRNIDX, 0 FUNCRIDX, INTERID, D.ACTNUMST, C.ACTDESCR, CRDTAMNT, DEBITAMT, ORCRDAMT, ORDBTAMT, ORCTRNUM, ORDOCNUM, ORMSTRID, ORMSTRNM, ORTRXTYP, A.MCTRXSTT, A.XCHGRATE, A.DENXRATE 
	from GL10001 A INNER JOIN GL10000 B ON A.JRNENTRY = B.JRNENTRY INNER JOIN GL00100 C ON A.ACTINDX = C.ACTINDX INNER JOIN GL00105 D ON A.ACTINDX = D.ACTINDX
	WHERE A.JRNENTRY = @IO_iOUTJournalEntry
END

UPDATE ACA_RID10000 SET ACA_RID_Last = 0 WHERE TXDTLTYP = 1 AND DOCTYPE = 9 AND VCHRNMBR = @VCHRNMBR AND ACA_RID_Last = 1 

INSERT INTO ACA_RID10000 SELECT 1 TXDTLTYP, 9 DOCTYPE, @VCHRNMBR, 2 ACA_RID_Origen, @YEAR1 YEAR1, @PERIODID MONTH1, @TRXDATE TRXDATE, 2 ACA_RID_Tax_Status, 1 ACA_RID_Last, 
CONVERT(char(8), getdate(), 112), '19000101 ' + CONVERT(char(12), getdate(), 114), @USERID USERID, @IO_iOUTJournalEntry JRNENTRY 


go