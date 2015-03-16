-- SELECT * FROM aevents
-- WHERE
-- 	opents::date = '2014-09-06' AND
-- 	countrycode = 'GB' AND
-- 	eventtypeid = 7

-- SELECT * FROM amarkets
-- WHERE
-- 	eventid = '27261475'


SELECT
	marketid,
	COUNT(marketid) AS nisse
FROM
	arunners
GROUP BY
 	marketid
HAVING 
	COUNT(marketid) > 9
ORDER BY
 	nisse ASC


-- SELECT * FROM araceprices
-- WHERE
-- 	marketid = '1.113812273'
-- 	AND
-- 	selectionid = 58805
