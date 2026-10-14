DROP PROC IF EXISTS [dbo].[bet_table]
GO
CREATE PROC [dbo].[bet_table]
AS
BEGIN
	create table #data (user_id int, match nvarchar(max), code nvarchar(max), money_win numeric(19, 2), balance numeric(19, 2), fee numeric(19, 2))
	select top 0 user_id, money_win, money_win as rate_of_win, balance, fee into #table from #data

	-- data
	exec [bet_ticket_result] '', '', '', 1, 2, 2, '', '', 'insert #data select user_id, match, code, money_win, balance, fee from #result where systotal = 0'
	insert into #table select distinct user_id, 0, 0, 0, 0 from #data

	-- lãi/lỗ
	update a set money_win = isnull(b.money_win, 0), balance = isnull(b.balance, 0), fee = isnull(b.fee, 0)
		from #table a 
			join (select user_id, sum(money_win) as money_win, sum(balance) as balance, sum(fee) as fee from #data where code <> '00' group by user_id) b on a.user_id = b.user_id
	
	select row_number()over(order by a.money_win desc) as stt, a.*, b.comment as name 
		from #table a left join vsysuserinfo b on a.user_id = b.id
	
	drop table if exists #data, #table
END
GO
exec bet_table