--Hash Join: 
--SQL Server chooses Hash Join as a physical operator for query in case of
--high volume of data that is not sorted or indexed. Two processes together make the
--Hash Join, which are Build and Probe. In Build process, it reads all rows from Build
--input (left-hand side input table) and creates an in-memory hash table based on
--the equijoin keys. In the Probe process, it reads all rows from the Probe input
--(right-hand side input table) based on equijoin keys and matches those rows
--in hash table created by Build process.

--Merge Join: 
--SQL Server chooses Merge Join as a physical operator for query in case
--of a sorted join expression. Merge Join requires one equijoin predicate along with a
--sorted input. It works better if the data is not as bulky as we have in the Hash Join; it
--is not a heavy-weight champion like Hash Join.

--Nested Loop Join: The Nested Loop Join operator works well with at least two result
--sets, and out of these, one is relatively small that is used as an outer loop input, and
--another result set with efficient index works as inner loop set. It supports equijoin and
--inequality operator. This is a simple form to understand as it is used to compare each
--row of left-hand side table with every row of right-hand side table. So if the dataset is
--big, nested loop process consumes more time.


--use
--OPTION(LOOP JOIN) for Nested Loop Join
--OPTION(HASH JOIN)for HashJoin
--OPTION(MERGEJOIN) for Merge Join
SELECT
sh.*
FROM
SalesOrdHeaderDemo AS sh
JOIN
SalesOrdDetailDemo AS sd
ON
sh.SalesOrderID=sd.SalesOrderID
WHERE
sh.SalesOrderID=43659
OPTION(HASH JOIN)
