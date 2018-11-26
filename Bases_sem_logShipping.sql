set nocount on;
DECLARE @tmp_log table
(status int,
is_primary int,
server varchar(200),
database_name varchar(200),
time_since_last_backup varchar(200),
last_backup_file varchar(200),
backup_threshold varchar(200),
is_backup_alert_enabled varchar(200),
time_since_last_copy varchar(200),
last_copied_file  varchar(250),
time_since_last_restore  varchar(200),
last_restored_file varchar(250),
last_restored_latency varchar(200),
restore_threshold varchar(200),
is_restore_alert_enabled varchar(200)
);

insert into @tmp_log
exec sp_executesql @stmt=N'exec sp_help_log_shipping_monitor',@params=N'';


select pri.DATABASE_NAME,seg.name
from @tmp_log pri right outer join sys.databases seg
on (pri.database_name=seg.name)

