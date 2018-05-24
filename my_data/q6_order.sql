SET SEARCH_PATH TO parlgov;
SELECT DISTINCT *
FROM q6
ORDER BY countryId desc,partyName desc;