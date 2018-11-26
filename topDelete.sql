-- Using the TOP operator inside the DELETE statement for data purges.
DECLARE @Criteria DATETIME,    @RowCount INT
SELECT  @Criteria = GETDATE() - 60, @RowCount = 10000
WHILE @RowCount = 10000 
    BEGIN
        DELETE TOP ( 10000 )
        FROM    ExampleTable
        WHERE   DateTimeCol < @Criteria
        SELECT  @RowCount = @@ROWCOUNT
    END





DECLARE @RowCount INT
SELECT  @RowCount = 10000
WHILE @RowCount = 10000 
    BEGIN
        DELETE TOP ( 10000 )
        FROM    ExampleTable        
        SELECT  @RowCount = @@ROWCOUNT
    END



--Using a counter to control amount of transactions
/*
BEGIN
    declare @SQL nvarchar(512)
    declare @nTopCount int
	declare @contador int
	set @contador = 1
    set @nTopCount = 10000000    
	print @SQL
	while @nTopCount > 0
    begin
		print @contador
		set @SQL = N'insert into REGISTROS (data,orderm) values(''' + convert(nvarchar, getdate()) + N''',' + convert(nvarchar(10), @contador) + N')'
		print @SQL
        exec sp_executesql @SQL
		set @contador = @contador + 1
        if @contador > @nTopCount
            break
        waitfor delay '00:00:01.000'
    end
END


*/
