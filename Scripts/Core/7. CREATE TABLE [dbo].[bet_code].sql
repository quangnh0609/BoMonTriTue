DROP TABLE IF EXISTS [dbo].[bet_code]
GO
CREATE TABLE [dbo].[bet_code](
	[code] [char](16) NOT NULL,
	[name] [nvarchar](128) NOT NULL,
	[part] [nvarchar](128) NOT NULL,
 CONSTRAINT [PK_bet_code] PRIMARY KEY CLUSTERED 
(
	[code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

INSERT INTO bet_code (code,name,part)VALUES(N'01',N'góc',N'H1')
INSERT INTO bet_code (code,name,part)VALUES(N'02',N'góc',N'H2')
INSERT INTO bet_code (code,name,part)VALUES(N'03',N'góc',N'Trận')
INSERT INTO bet_code (code,name,part)VALUES(N'11',N'chấp góc',N'H1')
INSERT INTO bet_code (code,name,part)VALUES(N'12',N'chấp góc',N'H2')
INSERT INTO bet_code (code,name,part)VALUES(N'13',N'chấp góc',N'Trận')
INSERT INTO bet_code (code,name,part)VALUES(N'21',N'bàn',N'H1')
INSERT INTO bet_code (code,name,part)VALUES(N'22',N'bàn',N'H2')
INSERT INTO bet_code (code,name,part)VALUES(N'23',N'bàn',N'Trận')
INSERT INTO bet_code (code,name,part)VALUES(N'31',N'chấp',N'H1')
INSERT INTO bet_code (code,name,part)VALUES(N'32',N'chấp',N'H2')
INSERT INTO bet_code (code,name,part)VALUES(N'33',N'chấp',N'Trận')
INSERT INTO bet_code (code,name,part)VALUES(N'41',N'châu âu',N'H1')
INSERT INTO bet_code (code,name,part)VALUES(N'42',N'châu âu',N'H2')
INSERT INTO bet_code (code,name,part)VALUES(N'43',N'châu âu',N'Trận')
INSERT INTO bet_code (code,name,part)VALUES(N'46',N'vô địch',N'')
INSERT INTO bet_code (code,name,part)VALUES(N'47',N'vua phá lưới',N'')
INSERT INTO bet_code (code,name,part)VALUES(N'48',N'vua kiến tạo',N'')
INSERT INTO bet_code (code,name,part)VALUES(N'51',N'thẻ',N'H1')
INSERT INTO bet_code (code,name,part)VALUES(N'52',N'thẻ',N'H2')
INSERT INTO bet_code (code,name,part)VALUES(N'53',N'thẻ',N'Trận')
INSERT INTO bet_code (code,name,part)VALUES(N'61',N'chấp thẻ',N'H1')
INSERT INTO bet_code (code,name,part)VALUES(N'62',N'chấp thẻ',N'H2')
INSERT INTO bet_code (code,name,part)VALUES(N'63',N'chấp thẻ',N'Trận')


