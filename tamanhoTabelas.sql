CREATE TABLE #tempTable
( 
    [name] NVARCHAR(128),
    [rows] CHAR(11),
    reserved VARCHAR(18), 
    data VARCHAR(18), 
    index_size VARCHAR(18),
    unused VARCHAR(18)
) 


insert #tempTable exec sp_MSforeachtable 'EXEC sp_spaceused ''?'''


select [name], [rows], 
cast(replace(reserved, ' KB','') as int) as reserved, 
cast(replace(data, ' KB','') as int) as data, 
cast(replace(index_size, ' KB','') as int) as index_size, 
cast(replace(unused, ' KB','') as int) as unused
into #finalTable
from #tempTable


-- Modifique o order by abaixo para ter a ordenação desejada
select * from #finalTable order by data desc


drop table #finalTable
drop table #tempTable
