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
DROP VIEW IF EXISTS election_winners CASCADE;
create view election_winners as
select  election.id as election_id , cabinet_party.party_id
from election join cabinet
on election.id = cabinet.election_id
join cabinet_party
on cabinet.id = cabinet_party.cabinet_id
where cabinet_party.pm = true;


DROP VIEW IF EXISTS winners_comb CASCADE;
CREATE VIEW winners_comb as 
select country.name as country,election_winners.election_id,election.previous_parliament_election_id as prev_id,election_result.id as res_id,election_result.party_id
from election_winners,election,election_result,country
where election_winners.election_id = election.id and election.id = election_result.election_id and election.country_id=country.id and election_winners.party_id=election_result.party_id; 


DROP VIEW IF EXISTS RepeatParty CASCADE;
CREATE VIEW RepeatParty as
SELECT w1.country,count(*) as num_repeat_party
FROM winners_comb w1, winners_comb w2
WHERE w1.prev_id IS NOT NULL AND  w1.prev_id=w2.election_id AND w1.party_id=w2.party_id and w1.res_id<>w2.res_id
GROUP BY w1.country;




DROP VIEW IF EXISTS NumElection CASCADE;
CREATE VIEW NumElection as 
SELECT country.name as country,count(election.id) as num_elections
FROM election,country 
WHERE election.country_id=country.id and election.e_type = 'Parliamentary election'
GROUP BY country.name;



DROP VIEW IF EXISTS PM CASCADE;
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








		