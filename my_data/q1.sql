SET SEARCH_PATH TO parlgov;
drop table if exists q1 cascade;

-- You must not change this table definition.

create table q1(
century VARCHAR(2),
country VARCHAR(50), 
left_right REAL, 
state_market REAL, 
liberty_authority REAL
);

-- Define views for your intermediate steps here.
-- get all of the winning parties based on the cabinet

DROP VIEW IF EXISTS election_winners CASCADE;
create view election_winners as
select election.id as election_id , cabinet_party.party_id
from election join cabinet
on election.id = cabinet.election_id
join cabinet_party
on cabinet.id = cabinet_party.cabinet_id
where cabinet_party.pm = true;

-- Combining election details for each paety and election details
DROP VIEW IF EXISTS election_comb CASCADE;
CREATE VIEW election_comb as 
SELECT country.name as country, election_id, alliance_id,party_id,party.name as party,election_result.id as res_id,election.e_date as e_date
FROM election,election_result,country,party
WHERE election.id=election_result.election_id and election.country_id=country.id and election_result.party_id = party.id and election.e_type='Parliamentary election';

-- Joining election result with election winners
DROP VIEW IF EXISTS all_winners CASCADE;
CREATE VIEW all_winners AS
SELECT e.country,e.election_id,e.alliance_id,e.party_id,e.party,e.res_id,e.e_date
FROM election_comb e, election_winners w
WHERE e.election_id= w.election_id AND e.party_id=w.party_id;

--Winners without allowance
DROP VIEW IF EXISTS winners_na CASCADE;
CREATE VIEW winners_na AS
SELECT * FROM all_winners WHERE alliance_id is NULL AND res_id NOT IN (SELECT alliance_id FROM election_comb WHERE alliance_id IS NOT NULL);

--Winners from election winners comb with one representative from alliance
DROP VIEW IF EXISTS  winners_a_one CASCADE;
CREATE VIEW winners_a_one AS
SELECT * FROM all_winners except SELECT * FROM winners_na;

--election winners with alliance
DROP VIEW IF EXISTS  winners_a CASCADE;
CREATE VIEW winners_a AS
SELECT * FROM election_comb
WHERE   (alliance_id IS NULL AND (election_id,party_id) NOT IN (SELECT election_id,party_id FROM winners_na) 
			AND (election_id,party_id) IN (SELECT election_id,party_id FROM all_winners) 
		)
		OR
		( alliance_id IS NOT NULL AND (alliance_id,election_id) in (SELECT res_id,election_id FROM all_winners)

		);


-- Assigning alliance id to where alliance id is null for that group so that we can group them

--UPDATE winners_a set alliance_id= res_id where alliance_id is NULL;
DROP VIEW IF EXISTS winners_a_null CASCADE;
CREATE VIEW winners_a_null as
select country,election_id, res_id as alliance_id,party_id,party,res_id,e_date
FROM winners_a where alliance_id IS NULL;

-- All the parties that are not part of the alliance
DROP VIEW IF EXISTS winners_a_not_null CASCADE;
CREATE VIEW winners_a_not_null as 
select * FROM
winners_a where alliance_id IS NOT NULL;

--All the parties that formed alliance
DROP VIEW IF EXISTS winners_comb_al CASCADE;
CREATE VIEW winners_comb_al AS
select * from winners_a_null UNION select * from winners_a_not_null;

--All the parties that are not part of any alliance
DROP VIEW IF EXISTS winners_comb_nal CASCADE;
CREATE VIEW winners_comb_nal AS
SELECT * FROM winners_na;


-- Filtering attributes for alliance and single parties
DROP VIEW IF EXISTS alliance_parties CASCADE;
CREATE VIEW alliance_parties as
SELECT  election_id,party_id,alliance_id,country,e_date
FROM winners_comb_al;


DROP VIEW IF EXISTS single_parties  CASCADE;
CREATE VIEW single_parties as
SELECT  election_id,party_id,country,e_date
FROM winners_comb_nal;



-- Aveage of the alliance parties
DROP VIEW IF EXISTS alliance_stats  CASCADE;
CREATE VIEW alliance_stats as
SELECT CASE WHEN EXTRACT(year FROM e_date)>=1901 AND EXTRACT(year FROM e_date) <=2000 THEN '20'
            ELSE '21' END AS century,
            country,avg(left_right) as left_right ,avg(state_market) as state_market ,avg(liberty_authority) as liberty_authority
FROM alliance_parties,party_position
WHERE alliance_parties.party_id=party_position.party_id AND 
EXTRACT(year FROM e_date)>=1901 AND EXTRACT(year FROM e_date) <=2100
GROUP BY alliance_parties.alliance_id,century,country;


-- Collecting stats for individual parties
DROP VIEW IF EXISTS party_stats  CASCADE;
CREATE VIEW party_stats as
SELECT CASE WHEN EXTRACT(year FROM e_date)>=1901 AND EXTRACT(year FROM e_date) <=2000 THEN '20'
            ELSE '21' END AS century,
            country,left_right ,state_market ,liberty_authority
FROM single_parties,party_position
WHERE single_parties.party_id=party_position.party_id AND 
EXTRACT(year FROM e_date)>=1901 AND EXTRACT(year FROM e_date) <=2100
GROUP BY century,country,party_position.party_id;




-- Average for combined alliance and individual parties
DROP VIEW IF EXISTS combined_stats  CASCADE;
CREATE VIEW combined_stats as
(SELECT * FROM alliance_stats) UNION ALL (SELECT * FROM party_stats);

insert into q1 
SELECT century,country,avg(left_right),avg(state_market),avg(liberty_authority)
FROM combined_stats
GROUP BY century,country;


