Create Function dbo.udf_split(@list varchar(8000), @delimiter char(1))
returns @t table (r varchar(8000))
As

Begin

set @list = replace(replace(@list,char(10),''),char(13),'')

insert @t
SELECT ltrim(SUBSTRING(@delimiter + @List + @delimiter , w.i + 1, CHARINDEX(@delimiter , @delimiter + @List + @delimiter , w.i + 1) - w.i - 1)) value
FROM (
SELECT top 100 percent v0.n + v1.n + v2.n + v3.n i
FROM (
SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
)v0,
(
SELECT 0 n UNION ALL SELECT 16 UNION ALL SELECT 32 UNION ALL SELECT 48 UNION ALL SELECT 64 UNION ALL SELECT 80 UNION ALL SELECT 96 UNION ALL SELECT 112 UNION SELECT 128 UNION ALL SELECT 144 UNION ALL SELECT 160 UNION ALL SELECT 176 UNION ALL SELECT 192 UNION ALL SELECT 208 UNION ALL SELECT 224 UNION ALL SELECT 240
) v1,
(
SELECT 0 n UNION ALL SELECT 256 UNION ALL SELECT 512 UNION ALL SELECT 768 UNION ALL SELECT 1024 UNION ALL SELECT 1280 UNION ALL SELECT 1536 UNION ALL SELECT 1792 UNION SELECT 2048 UNION ALL SELECT 2304 UNION ALL SELECT 2560 UNION ALL SELECT 2816 UNION ALL SELECT 3072 UNION ALL SELECT 3328 UNION ALL SELECT 3584 UNION ALL SELECT 3840
) v2,
(
SELECT 0 n UNION ALL SELECT 4096
) v3 order by i
) w 
WHERE w.i = CHARINDEX(@delimiter , @delimiter + @List + @delimiter , w.i) AND w.i < LEN(@delimiter + @List)

return 
End
