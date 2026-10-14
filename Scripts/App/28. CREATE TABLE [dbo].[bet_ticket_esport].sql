DROP TABLE IF EXISTS [dbo].[bet_ticket_esport]
GO

CREATE TABLE [dbo].[bet_ticket_esport] (
    [user_id]  INT           NOT NULL,
    [match_id] NVARCHAR(50)  NOT NULL,
    [code]     NVARCHAR(64)  NOT NULL,
    [money]    NUMERIC(19,0) NOT NULL,
    [datetime] DATETIME      NOT NULL DEFAULT GETDATE(),
    [clear]    BIT           NULL,
    CONSTRAINT [PK_bet_ticket_esport] PRIMARY KEY CLUSTERED ([user_id], [match_id], [code]),
    CONSTRAINT [FK_bet_ticket_esport_match] FOREIGN KEY ([match_id])
        REFERENCES [dbo].[bet_esport_match]([match_id])
)
GO
