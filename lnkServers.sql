SELECT a.name, a.product, a.provider, a.data_source, a.provider_string, a.catalog, b.remote_name
FROM sys.Servers a
LEFT OUTER JOIN sys.linked_logins b ON b.server_id = a.server_id
LEFT OUTER JOIN sys.server_principals c ON c.principal_id = b.local_principal_id
order by 1