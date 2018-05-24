SET SEARCH_PATH TO parlgov;
drop table if exists q4 cascade;

-- You must not change this table definition.


CREATE TABLE q4(
country VARCHAR(50),
num_elections INT,
num_repeat_party INT,
num_repeat_pm INT
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.

create view election_winners as
select distinct election.id as election_id , cabinet_party.party_id
from election join cabinet
on election.id = cabinet.election_id
join cabinet_party
on cabinet.id = cabinet_party.cabinet_id
where cabinet_party.pm = true;

create view election_comb as
	select country.name as country,electoral_system,election_id,election_result.party_id,election_result.id as res_id,election.previous_parliament_election_id as prev_id
	from election,election_result,country
	where election.id=election_result.election_id and election.country_id=country.id and election.e_type='Parliamentary election';

CREATE VIEW RepeatParty as
SELECT e1.country,count(e1.election_id) as num_repeat_party
FROM election_comb e1, election_comb e2
WHERE e1.prev_id IS NOT NULL AND e1.prev_id=e2.election_id AND e1.party_id=e2.party_id and e1.res_id!=e2.res_id and (e1.prev_id,e2.party_id) in (select election_id,party_id from election_winners) and (e1.election_id,e1.party_id) in (select election_id,party_id from election_winners)
GROUP BY e1.country;


CREATE VIEW W as
SELECT country.name as country,election_winners.election_id as eid,election_winners.party_id as pid,election.previous_parliament_election_id as prev_eid
FROM election_winners,election,country,election_result
WHERE election_winners.party_id=election_result.party_id and election_winners.election_id=election_result.election_id and election_result.election_id=election.id and election_winners.election_id=election.id AND election.country_id=country.id and election.e_type='Parliamentary election';
/*
CREATE VIEW RepeatParty as
SELECT w1.country,count(w1.eid) as num_repeat_party
FROM W w1, W w2
WHERE w1.prev_eid=w2.eid AND w1.pid=w2.pid and w1.eid<>w2.eid and w1.country=w2.country
GROUP BY w1.country;
*/


CREATE VIEW NumElection as 
SELECT country.name as country,count(election.id) as num_elections
FROM election,country 
WHERE election.country_id=country.id and election.e_type = 'Parliamentary election'
GROUP BY country.name;
/*
CREATE View PM as

SELECT country,count(cab) as num_repeat_pm FROM
			(select country.name as country,cabinet.name as cab, count(cabinet.election_id)
			FROM election_winners,cabinet,election,country
			WHERE election_winners.election_id=cabinet.election_id AND election_winners.election_id=election.id and election.country_id=country.id and election.e_type = 'Parliamentary election'
			GROUP BY country.name,cabinet.name
			HAVING count(cabinet.election_id)>1)A

		GROUP BY country
		;

	 
CREATE VIEW A as 
SELECT country,count(distinct num_elections) as num_elections,count(distinct num_repeat_party) as num_repeat_party,count(distinct pm_name) as num_repeat_pm
FROM NumElection NATURAL FULL JOIN RepeatParty NATURAL FULL JOIN PM
GROUP BY country;
*/


--SELECT * FROM q4;

--SELECT count(name),count(distinct name) FROM cabinet;
CREATE VIEW Z AS
select country.name as country,cabinet.name as cab, count(distinct cabinet.election_id)
			FROM election_winners,cabinet,election,country
			WHERE election_winners.election_id=cabinet.election_id AND election_winners.election_id=election.id and election.country_id=country.id and election.e_type = 'Parliamentary election'
			GROUP BY country.name, cabinet.name
			HAVING count(distinct cabinet.election_id)=1
		;
/*
CREATE VIEW PM as
	
	SELECT country, count(distinct cab) as num_repeat_pm FROM 
			select regexp_replace(cabinet.name::text, '([A-Za-z]*?)[ IV]+$', '\1') as cab
			FROM election_winners,cabinet,election,country
			WHERE election_winners.election_id=cabinet.election_id AND election_winners.election_id=election.id and election.country_id=country.id and election.e_type = 'Parliamentary election' AND election.country_id=cabinet.country_id
			and cabinet.name like '% %'
			)A
	GROUP BY country
		;


CREATE VIEW PM as
	
		SELECT country.name as country, count(distinct cabinet.election_id) FROM
				(SELECT regexp_replace(cabinet.name::text, '([A-Za-z]*?)[ IV]+$', '\1') as cab
				FROM cabinet,country
				WHERE cabinet.country_id = country.id
				)A
		GROUP BY country.name
		having count(cab>1);
	
--SELECT * FROM PM;
*/

CREATE VIEW cabinet_sm as
select country.name as country, start_date, election_id, regexp_replace(cabinet.name::text, '([A-Za-z]*?)[ IV]+$', '\1') as cab_name
FROM cabinet,country 
WHERE cabinet.country_id = country.id;
/*
CREATE VIEW repeat_pm as
select country,election_id,cab_name
from cabinet_sm c1
where c1.cab_name in (select cab_name from cabinet_sm where c1.start_date > cabinet_sm.start_date and c1.country=cabinet_sm.country);


CREATE VIEW PM as
select country,count(distinct election_id) as num_repeat_pm
FROM repeat_pm
GROUP BY country;
*/


CREATE VIEW PM as
	
	SELECT country, count(distinct cab) as num_repeat_pm FROM

		(select  country,cab from
				(select regexp_replace(cabinet.name::text, '([A-Za-z]*?)[ IV]+$', '\1') as cab,country.name as country
				FROM cabinet,country
				where cabinet.country_id=country.id
				)A
		GROUP BY country,cab
		HAVING count(*)>1)B
	GROUP BY country;




-- the answer to the query 
INSERT INTO q4 SELECT country FROM NumElection;
UPDATE q4 SET num_elections = (SELECT num_elections from NumElection WHERE NumElection.country=q4.country);
UPDATE q4 SET num_repeat_party = (SELECT num_repeat_party from RepeatParty WHERE RepeatParty.country=q4.country);
UPDATE q4 SET num_repeat_pm = (SELECT num_repeat_pm from PM WHERE PM.country=q4.country);

UPDATE q4 set num_elections=0 where num_elections is NULL;
UPDATE q4 set num_repeat_party=0 where num_repeat_party is NULL;
UPDATE q4 set num_repeat_pm=0 where num_repeat_pm is NULL;



--select regexp_replace(cabinet.name::text, '([A-Za-z]*?)[ IV]+$', '\1') as name from cabinet;








		