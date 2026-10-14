/*
delete dvcommand where sysid = 'bet_match'
delete dvcontrollers where controller_ref = 'bet_match'
delete command where sysid = 'bet_match'
delete wcommand where sysid = 'bet_match'
*/

INSERT INTO dvcommand (wmenu_id,wmenu_id0,menu_id,bar,bar2,icon_url,icon_color,status,sysid,action,xtype,xgroup)VALUES(N'89.00.00',N'',N'',N'Trí tuệ',N'Intel',N'',N'',N'1',N'',N'',N'',N'30')
INSERT INTO wcommand (wmenu_id,wmenu_id0,menu_id,bar,bar2,link,parameter,icon_url,status,icon,sysid,type,syscode,msys,target,xtype)VALUES(N'89.00.00',N'',N'89.00.00',N'Trí tuệ',N'Intel',N'',N'',N'',N'1',N'',N'',N'',N'',0,N'',N'00')

INSERT INTO dvcommand (wmenu_id,wmenu_id0,menu_id,bar,bar2,icon_url,icon_color,status,sysid,action,xtype,xgroup)VALUES(N'89.00.01',N'89.00.00',N'89.00.01',N'Trận đấu',N'Match',N'FileAccountOutline',N'#669bbd',N'1',N'bet_match',N'',N'',N'30')
INSERT INTO dvcontrollers (xtype,controller,controller_ref,stt,descript,system)VALUES(N'',N'bet_match',N'bet_match',8386,N'Trận đấu',0)
INSERT INTO dvcontrollers (xtype,controller,controller_ref,stt,descript,system)VALUES(N'',N'bet_match_insert',N'bet_match',8386,N'Thêm trận đấu',0)
INSERT INTO dvcontrollers (xtype,controller,controller_ref,stt,descript,system)VALUES(N'',N'bet_match_result',N'bet_match',8386,N'Thêm kết quả trận đấu',0)
INSERT INTO dvcontrollers (xtype,controller,controller_ref,stt,descript,system)VALUES(N'',N'bet_ticket_insert',N'bet_match',8386,N'Thêm vé cược',0)
INSERT INTO dvcontrollers (xtype,controller,controller_ref,stt,descript,system)VALUES(N'',N'bet_ticket_result',N'bet_match',8386,N'Xem vé cược',0)
INSERT INTO dvcontrollers (xtype,controller,controller_ref,stt,descript,system)VALUES(N'',N'bet_ticket_detail',N'bet_match',8386,N'Chi tiết vé cược',0)
INSERT INTO dvcontrollers (xtype,controller,controller_ref,stt,descript,system)VALUES(N'',N'bet_ticket_clear',N'bet_match',8386,N'Clear vé cược',0)
INSERT INTO dvcontrollers (xtype,controller,controller_ref,stt,descript,system)VALUES(N'',N'bet_like_over',N'bet_match',8386,N'Copy vé cược',0)
INSERT INTO dvcontrollers (xtype,controller,controller_ref,stt,descript,system)VALUES(N'',N'bet_report',N'bet_match',8386,N'Báo cáo',0)
INSERT INTO dvcontrollers (xtype,controller,controller_ref,stt,descript,system)VALUES(N'',N'bet_master_data',N'bet_match',8386,N'Master Data',0)
INSERT INTO dvcontrollers (xtype,controller,controller_ref,stt,descript,system)VALUES(N'',N'bet_master_data_detail',N'bet_match',8386,N'Detail Data',0)
INSERT INTO dvcontrollers (xtype,controller,controller_ref,stt,descript,system)VALUES(N'',N'bet_payment',N'bet_match',8386,N'Payment',0)
INSERT INTO dvcontrollers (xtype,controller,controller_ref,stt,descript,system)VALUES(N'',N'bet_payment_detail',N'bet_match',8386,N'Payment',0)
INSERT INTO dvcontrollers (xtype,controller,controller_ref,stt,descript,system)VALUES(N'',N'bet_chart',N'bet_match',8386,N'Chart',0)
INSERT INTO dvcontrollers (xtype,controller,controller_ref,stt,descript,system)VALUES(N'',N'bet_table',N'bet_match',8386,N'Chart',0)
INSERT INTO dvcontrollers (xtype,controller,controller_ref,stt,descript,system)VALUES(N'',N'bet_table_detail',N'bet_match',8386,N'Chart',0)
INSERT INTO command (menu_id,sysid,syscode,msys)VALUES(N'89.00.01',N'bet_match',N'',0)
INSERT INTO wcommand (wmenu_id,wmenu_id0,menu_id,bar,bar2,link,parameter,icon_url,status,icon,sysid,type,syscode,msys,target,xtype)VALUES(N'89.00.01',N'89.00.00',N'89.00.01',N'Trận đấu',N'Match',N'bet_match.aspx',N'',N'',N'1',N'b64Item',N'bet_match',N'D',N'',0,N'',N'00')

/*
select * from dvcommand where sysid = 'bet_match'
select * from dvcontrollers where controller = 'bet_match'
select * from command where sysid = 'bet_match'
select * from wcommand where sysid = 'bet_match'
*/