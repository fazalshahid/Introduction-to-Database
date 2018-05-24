
SET SEARCH_PATH TO parlgov;
drop table if exists q7 cascade;

-- You must not change this table definition.

DROP TABLE IF EXISTS q7 CASCADE;
CREATE TABLE q7(
partyId INT, 
partyFamily VARCHAR(50) 
);

-- Define views for your intermediate steps here.
DROP VIEW IF EXISTS election_winners CASCADE;
create view election_winners as
select  election.id as election_id , cabinet_party.party_id
from election join cabinet
on election.id = cabinet.election_id
join cabinet_party
on cabinet.id = cabinet_party.cabinet_id
where cabinet_party.pm = true;

-- Adding country name for each election and filtering necessary fields
DROP VIEW IF EXISTS all_election_comb CASCADE;
CREATE VIEW all_election_comb as 
SELECT country.name as country, election.id as election_id, election.previous_parliament_election_id as prev_pid,election.previous_ep_election_id as prev_epid
,election.e_date,election.e_type
FROM election,country
WHERE election.country_id=country.id;



--Combining election result with country name,party name, only parliamentary election
DROP VIEW IF EXISTS election_comb CASCADE;
CREATE VIEW election_comb as 
SELECT country.name as country, election_id, alliance_id,election_result.party_id,election_result.party_id as partyId,election_result.id as res_id,votes,election.previous_parliament_election_id as prev_pid,election.previous_ep_election_id as prev_epid
,election.e_date,election.e_type
FROM election,election_result,country,party
WHERE election.id=election_result.election_id and election.country_id=country.id and election_result.party_id = party.id and election.e_type='Parliamentary election';

-- There some views which are not necessary
-- Keeping the views as my understanding of the question is changing time by time

-- The ep elections which dont have previous ep election date
DROP VIEW IF EXISTS ep_election_no_prev_date CASCADE;
CREATE VIEW ep_election_no_prev_date AS
SELECT election_id,prev_pid,prev_epid,e_date,country
FROM all_election_comb
WHERE e_type='European Parliament';

-- The below two views are not used in the final query as we only cared about dates for any ep elections from any country
-- The ep elections for each country which are not first
--Assuming date comparison is for parties from the same country with the ep election
DROP VIEW IF EXISTS ep_election_not_first CASCADE;
CREATE VIEW ep_election_not_first AS
SELECT e1.election_id,e1.prev_epid,e1.prev_pid,e1.e_date, e2.e_date as prev_epdate,e1.country as ep_country, e2.country as prev_ep_country
FROM ep_election_no_prev_date e1, ep_election_no_prev_date e2
WHERE e1.prev_epid IS NOT NULL AND e1.prev_epid = e2.election_id;

-- Th first ep elections for each country
DROP VIEW IF EXISTS ep_election_first CASCADE;
CREATE VIEW ep_election_first AS
SELECT election_id,prev_epid,prev_pid,e_date, NULL as prev_epdate,country as ep_country,NULL as prev_ep_country
FROM ep_election_no_prev_date 
WHERE  prev_epid IS NULL;

-- this view has all the ep elections
DROP VIEW IF EXISTS ep_election CASCADE;
CREATE VIEW ep_election AS SELECT * FROM ep_election_first UNION SELECT * FROM ep_election_not_first;

-- Collecting all the parties either indivual or if they were part of alliance
DROP VIEW IF EXISTS all_winners CASCADE;
CREATE VIEW all_winners AS
SELECT * FROM election_comb WHERE (election_id,party_id) IN (SELECT * FROM election_winners);

--Winners without allowance
DROP VIEW IF EXISTS winners_na CASCADE;
CREATE VIEW winners_na AS
SELECT * FROM all_winners WHERE alliance_id is NULL AND res_id NOT IN (SELECT alliance_id FROM election_comb WHERE alliance_id IS NOT NULL);

--Winners from election winners comb with one representative from alliance
DROP VIEW IF EXISTS winners_a_one CASCADE;
CREATE VIEW winners_a_one AS
SELECT * FROM all_winners except SELECT * FROM winners_na;

--Winners with alliance
DROP VIEW IF EXISTS winners_a CASCADE;
CREATE VIEW winners_a AS
SELECT * FROM election_comb
WHERE   (alliance_id IS NULL AND (election_id,party_id) NOT IN (SELECT election_id,party_id FROM winners_na) 
			AND (election_id,party_id) IN (SELECT election_id,party_id FROM all_winners) 
		)
		OR
		( alliance_id IS NOT NULL AND (alliance_id,election_id) in (SELECT res_id,election_id FROM all_winners)

		);
-- All the parties that won any election
DROP VIEW IF EXISTS winners_comb CASCADE;
CREATE VIEW winners_comb AS
SELECT * FROM winners_a UNION SELECT * FROM winners_na;

-- Parties that won at least one election before a ep election
DROP VIEW IF EXISTS atleast_one_winner CASCADE;
CREATE VIEW atleast_one_winner AS
SELECT party_id
FROM winners_comb w
WHERE EXISTS(SELECT * from ep_election where w.e_date < ep_election.e_date);

-- Filtering parties that didnt win a election strictly before each ep election
DROP VIEW IF EXISTS not_strong_parties CASCADE;
CREATE VIEW not_strong_parties AS
SELECT w.party_id
FROM atleast_one_winner w, ep_election e
WHERE (
	NOT EXISTS( SELECT * from winners_comb w2 where w.party_id=w2.party_id
				and w2.e_date>=all (select e_date from ep_election where e_date <e.e_date) and  w2.e_date <e.e_date)
	)
	
	;

-- Subtracting not strong parties from potential strog parties to get the strong parties
DROP VIEW IF EXISTS answer1 CASCADE;
CREATE VIEW answer1 AS 
(SELECT party_id from atleast_one_winner) except (select party_id from not_strong_parties);

-- Joining party with party_family to add the attribute the family
DROP VIEW IF EXISTS answer2 CASCADE;
CREATE VIEW answer2 as SELECT answer1.party_id,party_family.family FROM
answer1 LEFT JOIN party_family on answer1.party_id = party_family.party_id;

-- Renaming the attributes for final answer
DROP VIEW IF EXISTS answer CASCADE;
CREATE VIEW answer as 
SELECT party_id as partyID, family as partyFamily FROM answer2;

insert into q7 select * from answer;